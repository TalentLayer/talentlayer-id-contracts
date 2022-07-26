// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IServiceRegistry {
    enum Status {
        Filled,
        Confirmed,
        Finished,
        Rejected,
        Opened
    }

    enum ProposalStatus {
        Pending,
        Validated,
        Rejected
    }

    struct Service {
        Status status;
        uint256 buyerId;
        uint256 sellerId;
        uint256 initiatorId;
        string serviceDataUri;
        uint256 countProposals;
        uint256 transactionId;
        uint256 platformId;
    }

    struct Proposal {
        ProposalStatus status;
        uint256 sellerId;
        address rateToken;
        uint256 rateAmount;
        string proposalDataUri;
    }

    function getService(uint256 _serviceId) external view returns (Service memory);

    function getProposal(uint256 _serviceId, uint256 _proposal) external view returns (Proposal memory);

    function afterDeposit(
        uint256 _serviceId,
        uint256 _proposalId,
        uint256 _transactionId
    ) external;

    function afterFullPayment(uint256 _serviceId) external;
}
