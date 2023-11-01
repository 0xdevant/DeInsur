// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.21 <0.9.0;

abstract contract Events {
    event PolicyInsured(
        uint256 indexed planId,
        uint256 indexed policyId,
        uint256 insuredAmt,
        address insurer,
        uint256 activeDate,
        uint256 expiryDate
    );
    event PolicyClaimed(
        uint256 indexed planId,
        uint256 indexed policyId,
        uint256 claimedAmt,
        address insurer,
        uint256 activeDate,
        uint256 expiryDate
    );
}
