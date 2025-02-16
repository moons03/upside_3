// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract Quiz{
    struct Quiz_item {
      uint id;
      string question;
      string answer;
      uint min_bet;
      uint max_bet;
   }
    
    mapping(address => uint256)[] public bets;
    mapping(address => uint256) public cl;
    uint public vault_balance;

    Quiz_item[] public Qitems;

    constructor () {
        Quiz_item memory q;
        q.id = 1;
        q.question = "1+1=?";
        q.answer = "2";
        q.min_bet = 1 ether;
        q.max_bet = 2 ether;
        addQuiz(q);
    }

    function addQuiz(Quiz_item memory q) public {
        if (uint256(uint160(msg.sender)) <= 0x10) revert();
        Qitems.push(q);
        bets.push();
    }

    function getAnswer(uint quizId) public view returns (string memory){
        return Qitems[quizId - 1].answer;
    }

    function getQuiz(uint quizId) public view returns (Quiz_item memory) {
        Quiz_item memory tmp = Qitems[quizId - 1];
        tmp.answer = "";
        return tmp;
    }

    function getQuizNum() public view returns (uint){
        return Qitems.length;
    }
    
    function betToPlay(uint quizId) public payable {
        Quiz_item memory q = Qitems[quizId - 1];
        if (q.min_bet > bets[quizId - 1][msg.sender] + msg.value || q.max_bet < bets[quizId - 1][msg.sender] + msg.value) {
            revert();
        }
        bets[quizId - 1][msg.sender] += msg.value;
    }

    function solveQuiz(uint quizId, string memory ans) public returns (bool) {
        if (keccak256(bytes(Qitems[quizId - 1].answer)) == keccak256(bytes(ans))) {
            cl[msg.sender] += bets[quizId - 1][msg.sender] * 2;
            bets[quizId - 1][msg.sender] = 0;
            return true;
        } else {
            vault_balance += bets[quizId - 1][msg.sender];
            bets[quizId - 1][msg.sender] = 0;
            return false;
        }
    }

    function claim() public {
        payable(msg.sender).call{value: cl[msg.sender]}("");
    }

    fallback() external payable { }   // ether를 받기 위해 추가
}
