// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.21 <0.9.0;

import { BaseScript } from "./Base.s.sol";
import { DeInsur } from "../src/DeInsur.sol";

contract Deploy is BaseScript {
    uint256 constant GENERAL_INSURANCE_PLAN_ID = 0;
    uint256 constant TRAVEL_INSURANCE_PLAN_ID = 1;
    uint256 constant HEALTH_INSURANCE_PLAN_ID = 2;
    uint256 constant DAILY_PRICE_RATE = 0.05 ether;
    uint256 constant MULTIPLIER_RATE_BP = 200;

    function run() public broadcast returns (DeInsur deInsur) {
        deInsur = new DeInsur
            {value: 1 ether}
            (GENERAL_INSURANCE_PLAN_ID, 
            TRAVEL_INSURANCE_PLAN_ID,
            HEALTH_INSURANCE_PLAN_ID,
            DAILY_PRICE_RATE, 
            MULTIPLIER_RATE_BP);
    }
}
