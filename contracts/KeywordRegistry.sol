// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * The KeywordRegistry manages the storage and retreival of keywords.
 */
contract KeywordRegistry is Ownable{
	event KeywordsAdded(string[] keywords);
	event KeywordsRemoved(string[] keywords);

	constructor() public {}

	function addKeywords (string[] memory keywords) public {
		emit KeywordsAdded(keywords);
	}

	function removeKeyword (string[] memory keywords) public {
		emit KeywordsRemoved(keywords);
	}
}