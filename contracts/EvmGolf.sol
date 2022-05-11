//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.12;
import "./interfaces/ILevel.sol";
import "hardhat/console.sol";

contract EvmGolf {
    struct Level {
        address author;
        RecordSolution recordSolution;
    }

    struct RecordSolution {
        address player;
        address solution;
    }

    mapping(ILevel => Level) private _levelsMapping; // level name -> bool
    ILevel[] private _levelAddresses;
    mapping(address => ILevel) private _authors; // author -> level
    mapping(ILevel => address) private _records; // level -> author
    mapping(ILevel => address) private _solutions; // level -> solution
    mapping(address => uint) private _victories; // author -> number of victories

    event LevelSolved(ILevel level, address solution, address player);
    event LevelFailed(ILevel level, address solution, address player);
    event LevelRecord(ILevel level, address solution, address player);

    error LevelAlreadyRegistered(ILevel level);
    error LevelFailedSubmission(ILevel level);
    error InvalidLevel();

    function _isLevelValid(address levelAddress) private returns (bool) {
        if (levelAddress.code.length == 0) {
            return false;
        }

        ILevel level = ILevel(levelAddress);
        if (bytes(level.name()).length == 0) {
            return false;
        }

        return true;
    }

    function registerLevel(address levelAddress) external {
        if (!_isLevelValid(levelAddress)) {
            revert InvalidLevel();
        }

        //add the new level to levels array
        ILevel level = ILevel(levelAddress);
        _levelAddresses.push(level);
    }

    //listado de los niveles
    function getLevels() external view returns (ILevel[] memory) {
        return _levelAddresses;
    }

    function getCountOfLevels() external view returns (uint256) {
        return (_levelAddresses.length);
    }

    function playLevel(ILevel level, address solution) external {
        bool success = level.submit(solution);
        address player = msg.sender;

        if (success) {
            emit LevelSolved(level, solution, player);
        } else {
            revert LevelFailedSubmission(level);
        }

        bool isRecord = _isRecord(level, solution);

        if (isRecord) {
            // Stores in solutions mapping
            address pastRecordHolder = _levelsMapping[level].recordSolution.player;

            // Save new record solution
            _levelsMapping[level].recordSolution = RecordSolution({player: player, solution: solution});

            // increments and decrements a corresponding victories mapping
            _decrementVictories(pastRecordHolder);
            _incrementVictories(player);

            emit LevelRecord(level, solution, player);
        }
    }

    function getVictories(address player) external view returns (uint) {
        return _victories[player];
    }

    function _decrementVictories(address player) private {
        // Do not let victories go negative
        if (_victories[player] > 0) {
            _victories[player] -= 1;
        }
    }

    function _incrementVictories(address player) private {
        _victories[player] += 1;
    }

    function _isRecord(ILevel level, address solution) private view returns (bool) {
        RecordSolution memory recordSolution = _levelsMapping[level].recordSolution;
        if (recordSolution.solution == address(0)) {
            return true;
        }
        return recordSolution.solution.code.length > solution.code.length;
    }
}
