// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "./interfaces/IDeInsur.sol";

contract DeInsur is IDeInsur, Ownable, Pausable {
    uint256 private constant _MIN_INSURED_AMOUNT = 1 ether;
    uint256 private constant _MAX_INSURED_AMOUNT = 1000 ether;
    uint256 private constant _MIN_INSURED_PERIOD = 3 days;
    uint256 private constant _MAX_EXPIRY_PERIOD = 30 days;
    uint256 private constant _BASIS_POINTS = 10_000;
    uint256 private constant _INSURED_AMOUNT_PRECISION = 1e18;

    uint256 public immutable generalInsurancePlanId;
    uint256 public immutable travelInsurancePlanId;
    uint256 public immutable healthInsurancePlanId;

    address public operator;

    Policy[] private _policies;

    uint256 public multiplierRateBP;
    mapping(uint256 => bool) public plansActivated; // planId => activated
    mapping(uint256 => uint256) public plansPriceRate; // planId => daily price rate

    /// @notice Setting caller as operator, activate travel insurance, update its price rate, and send ETH to contract
    /// as a treasury
    constructor(
        uint256 _generalInsurancePlanID,
        uint256 _travelInsurancePlanID,
        uint256 _healthInsurancePlanID,
        uint256 _dailyPriceRate,
        uint256 _multiplierRateBP
    )
        payable
        Ownable(_msgSender())
    {
        generalInsurancePlanId = _generalInsurancePlanID;
        travelInsurancePlanId = _travelInsurancePlanID;
        healthInsurancePlanId = _healthInsurancePlanID;
        operator = _msgSender();
        plansActivated[_travelInsurancePlanID] = true;
        plansPriceRate[_travelInsurancePlanID] = _dailyPriceRate;
        multiplierRateBP = _multiplierRateBP;

        // inject initial liqudiity as insurance reserve
        if (msg.value > 0) emit ReserveReceived(msg.sender, msg.value);
    }

    receive() external payable {
        emit ReserveReceived(msg.sender, msg.value);
    }

    /// @notice Purchase a policy
    /// @param planId Policy plan Id (i.e. 0 - 2)
    /// @param activeDate Unix timestamp of the policy to be activated
    /// @param expiryDate Unix timestamp of the policy to be expired
    /// @param insuredAmt Desired amount to be covered in the plan
    function insure(uint256 planId, uint256 activeDate, uint256 expiryDate, uint256 insuredAmt) external payable {
        if (!plansActivated[planId]) revert PlanNotActiviated();
        if (insuredAmt < _MIN_INSURED_AMOUNT || insuredAmt > _MAX_INSURED_AMOUNT) revert InvalidPolicySetup();
        if (expiryDate < activeDate + _MIN_INSURED_PERIOD) revert InvalidPolicySetup();

        uint256 policyPrice = _calculatePolicyPrice(planId, activeDate, expiryDate, insuredAmt);
        if (msg.value < policyPrice) revert InsufficientPayment();

        uint256 policyId = _policies.length;

        Policy memory p = Policy({
            planId: planId,
            price: policyPrice,
            insuredAmt: insuredAmt,
            insurer: _msgSender(),
            claimable: false,
            activeDate: activeDate,
            expiryDate: expiryDate
        });
        _policies.push(p);

        emit PolicyInsured(planId, policyId, insuredAmt, _msgSender(), activeDate, expiryDate);
    }

    function claim(uint256 planId, uint256 policyId) external whenNotPaused {
        Policy memory p = _policies[policyId];
        if (p.insurer != _msgSender()) revert NotPolicyOwner();
        if (block.timestamp < p.activeDate) revert PolicyNotActive();
        if (block.timestamp > p.expiryDate + _MAX_EXPIRY_PERIOD) revert PolicyExpired();
        if (!p.claimable) revert PolicyNotClaimable();

        // remove claimed policy from existing policies
        _policies[policyId] = _policies[_policies.length - 1];
        _policies.pop();

        (bool success,) = p.insurer.call{ value: p.insuredAmt }("");
        if (!success) revert ClaimFailed();

        emit PolicyClaimed(planId, policyId, p.insuredAmt, _msgSender(), p.activeDate, p.expiryDate);
    }

    /**
     * Policy Settings
     */

    /// @notice Set the new daily price rate for different policy plans
    /// @param planId The id of the policy plan
    /// @param dailyPriceRate Daily pricing rate in ETH
    function setPriceRate(uint256 planId, uint256 dailyPriceRate) external onlyOwner {
        if (dailyPriceRate == 0) revert ZeroInput();

        plansPriceRate[planId] = dailyPriceRate;
    }

    function setMultiplierRateBP(uint256 newMultiplierRateBP) external onlyOwner {
        if (newMultiplierRateBP == 0) revert ZeroInput();

        multiplierRateBP = newMultiplierRateBP;
    }

    function setPlanActivated(uint256 planId, bool isActivated) external onlyOwner {
        plansActivated[planId] = isActivated;
    }

    /// @notice To be called by operator bot after verifying the incident is eligible for claim
    /// @dev Set certain policy to be claimable after FunctionConsumer.latestResponse returns true
    function setPolicyClaimable(uint256 policyId, bool isClaimable) external onlyOperator {
        _policies[policyId].claimable = isClaimable;
    }

    function setOperator(address newOperator) external onlyOwner {
        if (newOperator == address(0)) revert ZeroInput();

        operator = newOperator;
    }

    function withdraw(address receiver) external onlyOwner {
        (bool sent,) = receiver.call{ value: address(this).balance }("");
        if (!sent) revert WithdrawFailed();
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * Modifiers and Internal Functions
     */

    modifier onlyOperator() {
        require(_msgSender() == operator, "Only operator allowed.");
        _;
    }

    function _calculatePolicyPrice(
        uint256 planId,
        uint256 activeDate,
        uint256 expiryDate,
        uint256 insuredAmt
    )
        internal
        view
        returns (uint256)
    {
        uint256 priceRateBySec = plansPriceRate[planId] / 1 days;
        uint256 benefitPeriodBySec = expiryDate - activeDate;

        uint256 totalBenefitPeriodFee = priceRateBySec * benefitPeriodBySec;
        uint256 multiplierBP = _calculateMultiplierBP(insuredAmt);
        return totalBenefitPeriodFee + totalBenefitPeriodFee * multiplierBP / _BASIS_POINTS;
    }

    /// @dev Use Basic Point for multiplier to calculate percentage,
    /// for every 1 ETH, increase policy price by `multiplierRateBP`
    function _calculateMultiplierBP(uint256 _insuredAmt) internal view returns (uint256 multiplierBP) {
        multiplierBP = _insuredAmt * multiplierRateBP / _INSURED_AMOUNT_PRECISION;
    }

    /**
     * Getters
     */

    function getPolicyPrice(
        uint256 planId,
        uint256 activeDate,
        uint256 expiryDate,
        uint256 insuredAmt
    )
        public
        view
        returns (uint256 policyPrice)
    {
        policyPrice = _calculatePolicyPrice(planId, activeDate, expiryDate, insuredAmt);
    }

    function getTotalNumOfPolicies() public view returns (uint256) {
        return _policies.length;
    }

    function getUserNumOfPolicy(address user) public view returns (uint256 userNumOfPolicy) {
        for (uint256 i; i < _policies.length; i++) {
            if (user == _policies[i].insurer) {
                userNumOfPolicy++;
            }
        }
    }

    function getUserPolicyIds(address user) public view returns (uint256[] memory userPolicyIds) {
        uint256 userNumOfPolicy = getUserNumOfPolicy(user);
        userPolicyIds = new uint[](userNumOfPolicy);

        for (uint256 i; i < _policies.length; i++) {
            uint256 counter;
            if (user == _policies[i].insurer) {
                userPolicyIds[counter] = i;
                counter++;
            }
        }
    }

    function isUserPolicy(address user, uint256 policyId) public view returns (bool) {
        uint256[] memory userPolicyIds = getUserPolicyIds(user);
        if (userPolicyIds.length == 0) return false;

        for (uint256 i; i < userPolicyIds.length; i++) {
            if (userPolicyIds[i] == policyId) {
                return true;
            }
        }
        return false;
    }
}
