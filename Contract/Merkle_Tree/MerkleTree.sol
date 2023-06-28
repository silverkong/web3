// SPDX-License-Identifier: MIT
// Created by EunKong.

pragma solidity ^0.8.18;

contract AccessTree {

    struct TreeNode {
        bytes32 leftChild;
        bytes32 rightChild;
    }

    mapping(bytes32 => TreeNode) public accessTree;
    bytes32[] public treeLeaves;

    function insertIntoAccessList(address userAddress) public {
        bytes32 leaf = keccak256(abi.encodePacked(userAddress));
        treeLeaves.push(leaf);
    }

    function constructTree() public {
        uint256 numberOfLeaves = treeLeaves.length;
        for (uint256 i = 0; i < numberOfLeaves; i += 2) {
            bytes32 leftLeaf = treeLeaves[i];
            bytes32 rightLeaf = (i + 1 < numberOfLeaves) ? treeLeaves[i + 1] : bytes32(0);
            bytes32 treeNode = keccak256(abi.encodePacked(leftLeaf, rightLeaf));
            accessTree[treeNode] = TreeNode(leftLeaf, rightLeaf);
        }
    }

    function checkIfAllowed(address userAddress) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(userAddress));
        bytes32 currentNode = leaf;
        while (accessTree[currentNode].leftChild != bytes32(0) && accessTree[currentNode].rightChild != bytes32(0)) {
            if (leaf == accessTree[currentNode].leftChild) {
                currentNode = keccak256(abi.encodePacked(accessTree[currentNode].leftChild, accessTree[currentNode].rightChild));
            } else {
                currentNode = keccak256(abi.encodePacked(accessTree[currentNode].rightChild, accessTree[currentNode].leftChild));
            }
        }
        return currentNode == treeLeaves[0];
    }

    function getTotalLeaves() public view returns (uint256) {
        return treeLeaves.length;
    }

    function getLeafAtIndex(uint256 index) public view returns (bytes32) {
        require(index < treeLeaves.length, "Index out of bounds");
        return treeLeaves[index];
    }
}
