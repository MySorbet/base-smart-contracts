// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract FreelanceEscrow is Ownable, ReentrancyGuard {
    IERC20 public usdcToken;

    enum ProjectState { Initiated, Closed }
    enum ScheduleState { Planned, Funded, Approved }

    struct Schedule {
        string shortcode;
        string description;
        uint256 value;
        ScheduleState state;
    }

    struct Project {
        address freelancer;
        address client;
        ProjectState state;
        uint256 totalSchedules;
        uint256 completeSchedules;
        uint256 value;
    }

    mapping(string => Project) public projects;
    mapping(string => mapping(uint256 => Schedule)) public schedules;

    address public treasuryAddress;
    uint16 public clientFee;
    uint16 public freelancerFee;

    event ProjectCreated(string projectId, address client, address freelancer);
    event ScheduleAdded(string projectId, uint256 scheduleId, uint256 value);
    event ScheduleFunded(string projectId, uint256 scheduleId, uint256 amount);
    event ScheduleApproved(string projectId, uint256 scheduleId, uint256 amount);
    event ProjectEnded(string projectId);

    constructor(address _usdcAddress, address _treasuryAddress, address initialOwner) Ownable(initialOwner) {
        usdcToken = IERC20(_usdcAddress);
        treasuryAddress = _treasuryAddress;
    }

    function createProject(string memory projectId, address client) external {
        require(projects[projectId].freelancer == address(0), "Project already exists");
        projects[projectId] = Project({
            freelancer: msg.sender,
            client: client,
            state: ProjectState.Initiated,
            totalSchedules: 0,
            completeSchedules: 0,
            value: 0
        });
        emit ProjectCreated(projectId, client, msg.sender);
    }

    function addSchedule(string memory projectId, string memory shortCode, string memory description, uint256 value) external {
        Project storage project = projects[projectId];
        require(project.freelancer == msg.sender, "Only freelancer can add schedules");
        require(project.state != ProjectState.Closed, "Project is closed");

        uint256 scheduleId = project.totalSchedules;
        schedules[projectId][scheduleId] = Schedule({
            shortcode: shortCode,
            description: description,
            value: value,
            state: ScheduleState.Planned
        });

        project.totalSchedules++;
        project.value += value;

        emit ScheduleAdded(projectId, scheduleId, value);
    }

    function fundSchedule(string memory projectId, uint256 scheduleId) external nonReentrant {
        Project storage project = projects[projectId];
        Schedule storage schedule = schedules[projectId][scheduleId];

        require(project.client == msg.sender, "Only client can fund schedules");
        require(project.state == ProjectState.Initiated, "Project is not initiated");
        require(schedule.state == ScheduleState.Planned, "Schedule is not in planned state");

        uint256 amount = schedule.value;
        uint256 feeAmount = (amount * clientFee) / 10000;
        uint256 totalAmount = amount + feeAmount;

        require(usdcToken.transferFrom(msg.sender, address(this), totalAmount), "Transfer failed");

        schedule.state = ScheduleState.Funded;

        emit ScheduleFunded(projectId, scheduleId, totalAmount);
    }

    function approveSchedule(string memory projectId, uint256 scheduleId) external nonReentrant {
        Project storage project = projects[projectId];
        Schedule storage schedule = schedules[projectId][scheduleId];

        require(project.client == msg.sender, "Only client can approve schedules");
        require(project.state == ProjectState.Initiated, "Project is not initiated");
        require(schedule.state == ScheduleState.Funded, "Schedule is not funded");

        uint256 amount = schedule.value;
        uint256 freelancerFeeAmount = (amount * freelancerFee) / 10000;
        uint256 freelancerAmount = amount - freelancerFeeAmount;

        require(usdcToken.transfer(project.freelancer, freelancerAmount), "Transfer to freelancer failed");
        require(usdcToken.transfer(treasuryAddress, freelancerFeeAmount), "Transfer to treasury failed");

        schedule.state = ScheduleState.Approved;
        project.completeSchedules++;

        emit ScheduleApproved(projectId, scheduleId, amount);
    }

    function endProject(string memory projectId) external {
        Project storage project = projects[projectId];
        require(msg.sender == project.client || msg.sender == project.freelancer, "Unauthorized");
        require(project.totalSchedules == project.completeSchedules, "Not all schedules are complete");

        project.state = ProjectState.Closed;

        emit ProjectEnded(projectId);
    }

    // Add other necessary functions (getters, setters, etc.)

    function setTreasuryAddress(address _treasuryAddress) external onlyOwner {
        treasuryAddress = _treasuryAddress;
    }

    function setClientFee(uint16 _clientFee) external onlyOwner {
        clientFee = _clientFee;
    }

    function setFreelancerFee(uint16 _freelancerFee) external onlyOwner {
        freelancerFee = _freelancerFee;
    }
}