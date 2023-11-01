// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.21 <0.9.0;

import { PRBTest } from "@prb/test/PRBTest.sol";
import { console2 } from "forge-std/console2.sol";
import { StdCheats } from "forge-std/StdCheats.sol";

import { DeInsur } from "../src/DeInsur.sol";
import { Constants } from "./utils/Constants.sol";
import { Events } from "./utils/Events.sol";

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
}

contract DeInsurTest is PRBTest, StdCheats, Constants, Events {
    DeInsur internal deInsur;

    address alice;
    address bob;

    /// @dev A function invoked before each test case is run.
    function setUp() public virtual {
        // init test users
        alice = makeAddr("alice");
        vm.deal(alice, 1000 ether);
        bob = makeAddr("bob");
        vm.deal(bob, 1000 ether);

        // deploy the contract for test
        deInsur = new DeInsur{value: 10000 ether}
            (GENERAL_INSURANCE_PLAN_ID, 
            TRAVEL_INSURANCE_PLAN_ID,
            HEALTH_INSURANCE_PLAN_ID,
            DAILY_PRICE_RATE, 
            MULTIPLIER_RATE_BP);
    }

    function test_Insure_PurchaseTravelPolicyWith7DaysExpiry() external {
        uint256 price =
            deInsur.getPolicyPrice(TRAVEL_INSURANCE_PLAN_ID, block.timestamp, block.timestamp + 7 days, 1 ether);
        console2.log(price);

        vm.startPrank(alice);
        vm.expectEmit(address(deInsur));
        emit PolicyInsured(
            TRAVEL_INSURANCE_PLAN_ID, 0, 1 ether, address(alice), block.timestamp, block.timestamp + 7 days
        );
        deInsur.insure{ value: price }(TRAVEL_INSURANCE_PLAN_ID, block.timestamp, block.timestamp + 7 days, 1 ether);
        vm.stopPrank();
    }

    function test_Claim_ClaimAfterPolicyIsSetClaimable() external {
        uint256 price =
            deInsur.getPolicyPrice(TRAVEL_INSURANCE_PLAN_ID, block.timestamp, block.timestamp + 7 days, 1 ether);
        console2.log(price);
        vm.prank(alice);
        vm.expectEmit(address(deInsur));
        emit PolicyInsured(
            TRAVEL_INSURANCE_PLAN_ID, 0, 1 ether, address(alice), block.timestamp, block.timestamp + 7 days
        );
        deInsur.insure{ value: price }(TRAVEL_INSURANCE_PLAN_ID, block.timestamp, block.timestamp + 7 days, 1 ether);

        deInsur.setPolicyClaimable(0, true);

        vm.prank(alice);
        vm.expectEmit(address(deInsur));
        emit PolicyClaimed(
            TRAVEL_INSURANCE_PLAN_ID, 0, 1 ether, address(alice), block.timestamp, block.timestamp + 7 days
        );
        deInsur.claim(TRAVEL_INSURANCE_PLAN_ID, 0);

        assertEq(deInsur.getTotalNumOfPolicies(), 0);
    }

    function test_GetUserPolicyIds_AfterSuccessfullyInsure() external {
        uint256 price =
            deInsur.getPolicyPrice(TRAVEL_INSURANCE_PLAN_ID, block.timestamp, block.timestamp + 7 days, 1 ether);

        vm.prank(alice);
        deInsur.insure{ value: price }(TRAVEL_INSURANCE_PLAN_ID, block.timestamp, block.timestamp + 7 days, 1 ether);

        uint256[] memory policyIds = deInsur.getUserPolicyIds(alice);
        uint256 aliceOwnedPolicy = deInsur.getUserNumOfPolicy(alice);

        assertEq(policyIds.length, aliceOwnedPolicy);
    }

    // /// @dev Fork test that runs against an Ethereum Mainnet fork. For this to work, you need to set
    // `API_KEY_ALCHEMY`
    // /// in your environment You can get an API key for free at https://alchemy.com.
    // function testFork_Example() external {
    //     // Silently pass this test if there is no API key.
    //     string memory alchemyApiKey = vm.envOr("API_KEY_ALCHEMY", string(""));
    //     if (bytes(alchemyApiKey).length == 0) {
    //         return;
    //     }

    //     // Otherwise, run the test against the mainnet fork.
    //     vm.createSelectFork({ urlOrAlias: "mainnet", blockNumber: 16_428_000 });
    //     address usdc = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    //     address holder = 0x7713974908Be4BEd47172370115e8b1219F4A5f0;
    //     uint256 actualBalance = IERC20(usdc).balanceOf(holder);
    //     uint256 expectedBalance = 196_307_713.810457e6;
    //     assertEq(actualBalance, expectedBalance);
    // }
}
