const Store = artifacts.require("Store");
var chaiAsPromised = require("chai-as-promised");
var chai = require("chai");
const { assert } = require("chai");
chai.use(chaiAsPromised);
var expect = chai.expect;
var store;

contract("Store contract", accounts => {
    describe("Start initialize smart contract", function() {
        it("Contract deployment", async() => {
            storeInstance = await Store.deployed();
            assert(storeInstance != undefined, "Smart contract should be defined");
        });

        it("Should check account of OF ADMIN", function() {
            return storeInstance.ADMIN().then(function(result) {
                assert(result == accounts[0], "Should only admin can initialize");
            });
        });

        it("Should check fee user app", function() {
            return storeInstance.FEE_USE_APP().then(function(result) {
                assert(result == 10000000000000000, "Should only admin can initialize");
            });
        });

        it("Should check value swap token ERC20 each 1ETH", function() {
            return storeInstance.VALUE_SWAP_TOKEN().then(function(result) {
                assert(result == 1000, "Should only admin can initialize");
            });
        });

        it("Should check value space time to CLAIM", function() {
            return storeInstance.SPACE_TIME_CLAIM().then(function(result) {
                assert(result == 0, "SPACE_TIME_CLAIM must be");
            });
        });

        it("Should check value space time to REFUND", function() {
            return storeInstance.SPACE_TIME_REFUND().then(function(result) {
                assert(result == 0, "SPACE_TIME_REFUND must be)");
            });
        });
    })
})