// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Lottery {
    uint256 public round = 1;

    mapping(uint256 => uint256) public roundStartTime;
    mapping(uint256 => bool) public roundDrawn;
    mapping(uint256 => uint16) public winningNumbers;
    mapping(uint256 => uint256) public roundPot;
    mapping(uint256 => address[]) public roundPlayers;
    mapping(uint256 => mapping(address => uint16)) public tickets;
    mapping(uint256 => mapping(address => bool)) public hasBought;
    mapping(address => uint256) public lastClaimedRound;

    function buy(uint16 _number) external payable {
        require(msg.value == 0.1 ether);

        if (roundStartTime[round] == 0) {
            roundStartTime[round] = block.timestamp;
        } else {
            if (!roundDrawn[round]) {
                require(block.timestamp < roundStartTime[round] + 24 hours);
            } else {
                round++;
                roundStartTime[round] = block.timestamp;
            }
        }

        require(!hasBought[round][msg.sender]);
        hasBought[round][msg.sender] = true;
        tickets[round][msg.sender] = _number;
        roundPlayers[round].push(msg.sender);
    }

    function draw() external {
        require(!roundDrawn[round]);
        require(block.timestamp >= roundStartTime[round] + 24 hours);

        roundPot[round] = address(this).balance;
        winningNumbers[round] = uint16(
            uint256(keccak256(abi.encodePacked(round))) % 10000
        );
        roundDrawn[round] = true;
    }

    function claim() external {
        uint256 r = lastClaimedRound[msg.sender] + 1;
        require(roundStartTime[r] != 0);
        require(roundDrawn[r]);
        require(hasBought[r][msg.sender]);

        lastClaimedRound[msg.sender] = r;

        if (tickets[r][msg.sender] != winningNumbers[r]) {
            return;
        }

        uint256 winnersCount = 0;
        address[] storage players = roundPlayers[r];
        for (uint256 i = 0; i < players.length; i++) {
            if (tickets[r][players[i]] == winningNumbers[r]) {
                winnersCount++;
            }
        }
            require(winnersCount > 0);

        uint256 payout = roundPot[r] / winnersCount;
        payable(msg.sender).call{value: payout}("");
    }

    function winningNumber() external view returns (uint16) {
        require(roundStartTime[round] != 0);
        require(roundDrawn[round]);
        return winningNumbers[round]; 
    }
}