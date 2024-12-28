// SPDX-License-Identifier: BSD-3-Clause-Clear
// WARNING THIS IS AN EXPERIMENTAL CONTRACT AND IS NOT READY FOR PRODUCTION USE

pragma solidity >=0.8.19 <0.9.0;

import "@fhenixprotocol/contracts/FHE.sol";
import "@fhenixprotocol/contracts/access/Permissioned.sol";

contract Voting is Permissioned {
    uint8 internal constant MAX_OPTIONS = 4;

    // Pre-compute these to prevent unnecessary gas usage for the users
    // euint16 internal _zero = FHE.asEuint16(0);
    // euint16 internal _one = FHE.asEuint16(1);
    euint32 internal _u32Sixteen = FHE.asEuint32(16);
    euint8[MAX_OPTIONS] internal _encOptions = [FHE.asEuint8(0), FHE.asEuint8(1), FHE.asEuint8(2), FHE.asEuint8(3)];

    string public proposal;
    string[] public options;
    uint public voteEndTime;
    euint16[MAX_OPTIONS] internal _tally = [FHE.asEuint16(0),FHE.asEuint16(0),FHE.asEuint16(0),FHE.asEuint16(0)]; // Since every vote is worth 1, I assume we can use a 16-bit integer

    euint8 internal _winningOption;
    euint16 internal _winningTally;

    mapping(address => bool) public voters;

    mapping(address => euint8) internal _votes;

    bool public finalized;

    constructor(string memory _proposal, string[] memory _options, uint votingPeriod, address[] memory _voters) {
        require(options.length <= MAX_OPTIONS, "too many options!");

        proposal = _proposal;
        options = _options;
        voteEndTime = block.timestamp + votingPeriod;

        for (uint i; i < _voters.length; i++) {
            voters[_voters[i]] = true;
        }
    }

    function vote(inEuint8 memory voteBytes) public {
        // require voter to be in the list of voters
        require(voters[msg.sender]);

        require(block.timestamp < voteEndTime, "voting is over!");
        // require(!FHE.isInitialized(_votes[msg.sender]), "already voted!");
        require(!finalized, "voting is finalized!");

        euint8 encryptedVote = FHE.asEuint8(voteBytes); // Cast bytes into an encrypted type

        ebool voteValid = _requireValid(encryptedVote);

        _votes[msg.sender] = encryptedVote;
        _addToTally(encryptedVote, voteValid /* , _one */);
    }

    function finalize() public {
        require(voteEndTime < block.timestamp, "voting is still in progress!");
        require(!finalized, "voting is already finalized!");

        finalized = true;

        _winningOption = _encOptions[0];
        _winningTally = _tally[0];
        for (uint8 i = 1; i < options.length; i++) {
            euint16 newWinningTally = FHE.max(_winningTally, _tally[i]);
            _winningOption = FHE.select(newWinningTally.gt(_winningTally), _encOptions[i], _winningOption);
            _winningTally = newWinningTally;
        }
    }

    function winning() public view returns (uint8, uint16) {
        require(voteEndTime < block.timestamp, "voting is still in progress!");
        require(finalized, "voting is not finalized!");
        return (FHE.decrypt(_winningOption), FHE.decrypt(_winningTally));
    }

    function getUserVote(
        Permission memory signature
    ) public view onlyPermitted(signature, msg.sender) returns (bytes memory) {
    // ) public view onlyPermitted(signature, msg.sender) returns (string memory) {   // for remix compiling
        require(FHE.isInitialized(_votes[msg.sender]), "no vote found!");
        return FHE.sealoutput(_votes[msg.sender], signature.publicKey);
    }

    function _requireValid(euint8 encryptedVote) internal pure returns (ebool) {
        // TODO actually check the vote is valid.
        // Make sure that: (0 <= vote <= options.length)
        return encryptedVote.lte(FHE.asEuint8(MAX_OPTIONS - 1));
        //FHE.req(isValid);
    }

    function _addToTally(euint8 option, ebool voteValid /* , euint16 amount */) internal {
        // We don't want to leak the user's vote, so we have to change the tally of every option.
        // So for example, if the user voted for option 1:
        // tally[0] = tally[0] + enc(0)
        // tally[1] = tally[1] + enc(1)
        // etc ..
        for (uint8 i = 0; i < options.length; i++) {
            // euint16 amountOrZero = FHE.select(option.eq(_encOptions[i]), _one, _zero);
            ebool amountOrZero = option.eq(_encOptions[i]).and(voteValid); // `eq()` result is known to be enc(0) or enc(1)
            _tally[i] = _tally[i] + amountOrZero.toU16(); // `eq()` result is known to be enc(0) or enc(1)
        }
    }
}