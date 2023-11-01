// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.21 <0.9.0;

abstract contract Constants {
    uint256 constant GENERAL_INSURANCE_PLAN_ID = 0;
    uint256 constant TRAVEL_INSURANCE_PLAN_ID = 1;
    uint256 constant HEALTH_INSURANCE_PLAN_ID = 2;
    uint256 constant DAILY_PRICE_RATE = 0.05 ether;
    uint256 constant MULTIPLIER_RATE_BP = 200;
}
