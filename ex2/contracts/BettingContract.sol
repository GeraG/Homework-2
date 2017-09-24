pragma solidity ^0.4.15;

contract BettingContract {
	/* Standard state variables */
	address owner;
	address public gamblerA;
	address public gamblerB;
	address public oracle;
	uint[] outcomes;
	bool decisionMade;
	uint ownerPercent;

	/* Structs are custom data structures with self-defined parameters */
	struct Bet {
		uint outcome;
		uint amount;
		bool initialized;
	}

	/* Keep track of every gambler's bet */
	mapping (address => Bet) bets;
	/* Keep track of every player's winnings (if any) */
	mapping (address => uint) winnings;

	/* Add any events you think are necessary */
	event BetMade(address gambler);
	event BetClosed();

	/* Uh Oh, what are these? */
	modifier OwnerOnly() {
		require(msg.sender == owner);
		_;
	}
	modifier OracleOnly() {
		require(msg.sender == oracle);
		_;
	}

    /* Constructor function, where owner and outcomes are set */
	function BettingContract(uint[] _outcomes) {
		owner = msg.sender;
		outcomes = _outcomes;
		ownerPercent = 1;
	}

	/* Owner chooses their trusted Oracle */
	function chooseOracle(address _oracle) OwnerOnly() returns (address) {
		oracle = _oracle;
		decisionMade = false;
		return oracle;
	}

	/* Gamblers place their bets, preferably after calling checkOutcomes */
	function makeBet(uint _outcome) payable returns (bool) {
		if (msg.sender == owner || msg.sender == oracle) {
			return false;
		}
		if (bets[msg.sender].initialized) {
			return false;
		}
		for (uint i = 0; i < outcomes.length; i++) {
			if (outcomes[i] == _outcome) {
				break;
			}
			if (i == outcomes.length - 1) {
				return false;
			}
		}
		if (bets[gamblerA].initialized == false) {
			gamblerA = msg.sender;
			bets[gamblerA] = Bet(_outcome, msg.value, true);
			BetMade(msg.sender);
			return true;
		} else if (bets[gamblerB].initialized == false) {
			gamblerB = msg.sender;
			bets[gamblerB] = Bet(_outcome, msg.value, true);
			BetMade(msg.sender);
			BetClosed();
			return true;
		}
		
		return false;
	}

	/* The oracle chooses which outcome wins */
	function makeDecision(uint _outcome) OracleOnly() {
		if (decisionMade) {
			return;
		}

		if (bets[gamblerA].initialized == false || bets[gamblerB].initialized == false) {
			return;
		}

		uint ownerTakeA = (bets[gamblerA].amount * ownerPercent) / 100;
		uint ownerTakeB = (bets[gamblerB].amount * ownerPercent) / 100;

		if (bets[gamblerA].outcome != _outcome && bets[gamblerB].outcome != _outcome) {
			winnings[oracle] += bets[gamblerA].amount + bets[gamblerB].amount - ownerTakeA - ownerTakeB;
			winnings[owner] += ownerTakeA + ownerTakeB;
			decisionMade = true;
			return;
		}

		if (bets[gamblerA].outcome == _outcome) {
			winnings[gamblerA] += bets[gamblerA].amount - ownerTakeA;
		} else {
			winnings[gamblerB] += bets[gamblerA].amount - ownerTakeA;
		}

		if (bets[gamblerB].outcome == _outcome) {
			winnings[gamblerB] += bets[gamblerB].amount - ownerTakeB;
		} else {
			winnings[gamblerA] += bets[gamblerB].amount - ownerTakeB;
		}

		winnings[owner] += ownerTakeA + ownerTakeB;
		decisionMade = true;
	}

	/* Allow anyone to withdraw their winnings safely (if they have enough) */
	function withdraw(uint withdrawAmount) returns (uint remainingBal) {
		if (winnings[msg.sender] > 0) {
			winnings[msg.sender] -= withdrawAmount;
			msg.sender.transfer(withdrawAmount);
			return winnings[msg.sender];
		}
	}
	
	/* Allow anyone to check the outcomes they can bet on */
	function checkOutcomes() constant returns (uint[]) {
		return outcomes;
	}
	
	/* Allow anyone to check if they won any bets */
	function checkWinnings() constant returns(uint) {
		return winnings[msg.sender];
	}

	/* Call delete() to reset certain state variables. Which ones? That's upto you to decide */
	function contractReset() private {
		bets[gamblerA].initialized = false;
		bets[gamblerB].initialized = false;
		delete gamblerA;
		delete gamblerB;
		delete oracle;
	}

	/* Fallback function */
	function() payable {
		revert();
	}
}
