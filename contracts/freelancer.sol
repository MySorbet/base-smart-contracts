// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract Freelancer is Ownable(msg.sender), ReentrancyGuard {
    IERC20 public immutable deal_token;
    address public immutable treasury;

    enum MilestoneState { Initiated, Funded, Released }

    struct MilestoneData {
        address client;
        address freelancer;
        uint256 amount;
        MilestoneState milestone_state;
    }

    mapping(string => MilestoneData) public milestones;
    
    uint16 public client_fee;
    uint16 public freelancer_fee;

    event MilestoneFund(string milestone_id, address indexed client, address freelancer, uint256 amount);
    event MilestoneRelease(string milestone_id, address indexed client, address freelancer, uint256 amount);
    event MilestoneCancel(string milestone_id, address indexed client, address freelancer, uint256 amount);
    event MilestoneDispute(string milestone_id, address indexed client, address freelancer, uint256 client_amount, uint256 freelancer_amount);

    constructor(address _token, address _treasury) {
        deal_token = IERC20(_token);
        treasury = _treasury;
        client_fee = 0;
        freelancer_fee = 0;
    }

    function fundMilestone(string memory milestone_id, address freelancer, uint256 _amount) external {
        address client = msg.sender;
        MilestoneData storage milestone = milestones[milestone_id];
        require(_amount > 0, "Error: MileStone Amount should be bigger than zero");
        require(milestone.milestone_state == MilestoneState.Initiated, "Error: Milestone has already been funded");

        uint256 usdcAmount = _amount * (10000 + client_fee) / 10000;
        require(deal_token.transferFrom(msg.sender, address(this), usdcAmount), "Error: USDC transfer failed");

        if (client_fee > 0) {
            require(deal_token.transfer(treasury, _amount * client_fee / 10000), "Error: Treasury transfer failed");
        }
        milestone.client = client;
        milestone.freelancer = freelancer;
        milestone.amount = _amount;
        milestone.milestone_state = MilestoneState.Funded;

        emit MilestoneFund(milestone_id, client, freelancer, _amount);
    }

    function releaseMilestone(string memory milestone_id) external {
        MilestoneData storage milestone = milestones[milestone_id];

        require(msg.sender == milestone.client, "Unauthorized: Only Client can approve schedule");
        require(milestone.milestone_state == MilestoneState.Funded, "Milestone is not funded");

        uint256 freelancerAmount = milestone.amount * (10000 - freelancer_fee) / 10000;
        require(deal_token.transfer(milestone.freelancer, freelancerAmount), "Error: Freelancer transfer failed");
        if (freelancer_fee > 0) {
            require(deal_token.transfer(treasury, milestone.amount - freelancerAmount), "Error: Treasury transfer failed");
        }

        milestone.milestone_state = MilestoneState.Released;

        emit MilestoneRelease(milestone_id, milestone.client, milestone.freelancer, milestone.amount);
    }

    function cancelMilestone(string memory milestone_id) external onlyOwner {
        MilestoneData storage milestone = milestones[milestone_id];
        require(milestone.milestone_state == MilestoneState.Funded, "Milestone is not funded");

        require(deal_token.transfer(milestone.client, milestone.amount), "Error: Refund Client transfer failed");

        milestone.milestone_state = MilestoneState.Released;

        emit MilestoneCancel(milestone_id, milestone.client, milestone.freelancer, milestone.amount);
    }

    function disputeMilestone(string memory milestone_id, uint16 client_percent, uint16 freelancer_percent) external onlyOwner {
        MilestoneData storage milestone = milestones[milestone_id];
        require(client_percent + freelancer_percent == 10000, "Error: Percentages must sum to 10000 basis points");
        require(milestone.milestone_state == MilestoneState.Funded, "Milestone is not funded");
        
        uint256 clientAmount = milestone.amount * client_percent / 10000;
        uint256 freelancerAmount = milestone.amount * freelancer_percent / 10000;

        require(deal_token.transfer(milestone.client, clientAmount), "Client transfer failed");
        require(deal_token.transfer(milestone.freelancer, freelancerAmount), "Freelancer transfer failed");

        milestone.milestone_state = MilestoneState.Released;

        emit MilestoneDispute(milestone_id, milestone.client, milestone.freelancer, clientAmount, freelancerAmount);
    }

    function set_clientfee(uint16 _newfee) external onlyOwner {
        client_fee = _newfee;
    }

    function set_freelancerfee(uint16 _newfee) external onlyOwner {
        freelancer_fee = _newfee;
    }

    // View functions
    function get_milestone(string memory milestone_id) external view returns (MilestoneData memory) {
        return milestones[milestone_id];
    }
}
