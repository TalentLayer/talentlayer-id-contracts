// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * The KeywordRegistry manages the storage and retreival of keywords.
 */
contract KeywordRegistry is Ownable{
	
	string[] keywords;
	
	event KeywordCreated(uint256 keywordID, string keyword);

	event KeywordLinkedToService(uint256 keywordID, uint256 serviceID);

	constructor() public {}

	function addKeyword (string memory keyword) public returns (uint256 keywordID) {
		uint256 _keywordID = getKeywordID(keyword);
		if(_keywordID == keywords.length){
			keywords.push(keyword);
			emit KeywordCreated(_keywordID, keyword);
		}
		return _keywordID;
	}

	function linkKeywordToService(string memory keyword, uint256 serviceID) external {
		uint256 keywordID = addKeyword(keyword);
		emit KeywordLinkedToService(keywordID, serviceID);
	}

	function getKeywordID(string memory keyword) private view returns (uint256 id) {
		for(uint256 i = 0; i < keywords.length; i++){
			if (keccak256(abi.encodePacked(keywords[i])) == keccak256(abi.encodePacked(keyword))){
				return i;
			}
		}
		return keywords.length;
	}
}