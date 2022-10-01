// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface ITalentLayerMultipleArbitrableTransaction{
	struct Transaction {
        address sender; //pays recipient using the escrow
        address receiver; //intended recipient of the escrow
        address token; //token of the escrow
        uint256 amount; //amount locked into escrow
        uint256 jobId; //the jobId related to the transaction
    }

	function createTokenTransaction(
        uint256 _timeoutPayment,
        string memory _metaEvidence,
        address _adminWallet,
        uint256 _adminFeeAmount,
        uint256 _jobId,
        uint256 _proposalId
    ) external;

    function createETHTransaction(
        uint256 _timeoutPayment,
        string memory _metaEvidence,
        address _adminWallet,
        uint256 _adminFeeAmount,
        uint256 _jobId,
        uint256 _proposalId
    ) external payable;


	function release(
	    uint256 _transactionId,
	    uint256 _amount
	) external;

	function reimburse(
	    uint256 _transactionId,
	    uint256 _amount
	) external;
}