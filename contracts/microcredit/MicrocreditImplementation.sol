//SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.4;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "./interfaces/MicrocreditStorageV1.sol";

contract MicrocreditImplementation is
Initializable,
OwnableUpgradeable,
PausableUpgradeable,
ReentrancyGuardUpgradeable,
MicrocreditStorageV1
{
    using SafeERC20Upgradeable for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;

    event ManagerAdded(address indexed managerAddress, uint256 currentLentAmountLimit);

    event ManagerRemoved(address indexed managerAddress);

    event LoanAdded(
        address indexed userAddress,
        uint256 loanId,
        uint256 amount,
        uint256 period,
        uint256 dailyInterest,
        uint256 claimDeadline
    );

    event LoanCanceled(address indexed userAddress, uint256 loanId);

    event UserAddressChanged(address indexed oldWalletAddress, address indexed newWalletAddress);

    event LoanClaimed(address indexed userAddress, uint256 loanId);

    event RepaymentAdded(
        address indexed userAddress,
        uint256 loanId,
        uint256 repaymentAmount,
        uint256 currentDebt
    );

    /**
     * @notice Triggered when a borrower's manager has been changed
     *
     * @param borrowerAddress   The address of the borrower
     * @param managerAddress    The address of the new manager
     */
    event ManagerChanged(address indexed borrowerAddress, address indexed managerAddress);

    modifier onlyManagers() {
        require(_managerList.contains(msg.sender), "Microcredit: caller is not a manager");
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == 0xa34737409091eBD0726A3Ab5863Fc7Ee9243Edab, "Microcredit: caller is not admin");
        _;
    }


    /**
     * @notice Used to initialize the Microcredit contract
     *
     * @param _cUSDAddress      The address of the cUSD token
     * @param _revenueAddress   The address that collects all the interest
     */
    function initialize(address _cUSDAddress, address _revenueAddress) public initializer {
        __Ownable_init();
        __Pausable_init();
        __ReentrancyGuard_init();

        cUSD = IERC20(_cUSDAddress);
        revenueAddress = _revenueAddress;
    }

    /**
     * @notice Returns the current implementation version
     */
    function getVersion() external pure override returns (uint256) {
        return 1;
    }

    /**
     * @notice Returns the information of a user
     *
     * @param _userAddress           address of the user
     * @return userId                the userId
     * @return movedTo               the number of the user's loans
     * @return loansLength           the number of the user's loans
     */
    function walletMetadata(address _userAddress)
    external
    view
    override
    returns (
        uint256 userId,
        address movedTo,
        uint256 loansLength
    )
    {
        WalletMetadata memory _metadata = _walletMetadata[_userAddress];

        userId = _metadata.userId;
        movedTo = _metadata.movedTo;
        loansLength = _users[_metadata.userId].loansLength;
    }

    /**
     * @notice Returns the information of a user
     *
     * @param _userAddress           address of the user
     * @return userId                the userId
     * @return movedTo               the number of the user's loans
     * @return loansLength           the number of the user's loans
     */
    function walletMetadataOld(address _userAddress)
    external
    view
    returns (
        uint256 userId,
        address movedTo,
        uint256 loansLength
    )
    {
        WalletMetadata memory _metadata = _walletMetadata[_userAddress];

        userId = _metadata.userId;
        movedTo = _metadata.movedTo;
        loansLength = _usersOld[_metadata.userId].loans.length;
    }

    /**
     * @notice Returns the length of the walletList
     */
    function walletListLength() external view override returns (uint256) {
        return _walletList.length();
    }

    /**
     * @notice Returns an address from the walletList
     *
     * @param _index index value
     * @return address of the user
     */
    function walletListAt(uint256 _index) external view override returns (address) {
        return _walletList.at(_index);
    }

    /**
     * @notice Returns an address from the managerList
     *
     * @param _index index value
     * @return address of the manager
     */
    function managerListAt(uint256 _index) external view override returns (address) {
        return _managerList.at(_index);
    }

    /**
     * @notice Returns the length of the managerList
     */
    function managerListLength() external view override returns (uint256) {
        return _managerList.length();
    }

    function userLoans(address _userAddress, uint256 _loanId)
    external
    view
    override
    returns (
        uint256 amountBorrowed,
        uint256 period,
        uint256 dailyInterest,
        uint256 claimDeadline,
        uint256 startDate,
        uint256 currentDebt,
        uint256 lastComputedDebt,
        uint256 amountRepayed,
        uint256 repaymentsLength,
        uint256 lastComputedDate,
        address managerAddress
    )
    {
        _checkUserLoan(_userAddress, _loanId);

        WalletMetadata memory _metadata = _walletMetadata[_userAddress];
        Loan storage _loan = _users[_metadata.userId].loans[_loanId];

        amountBorrowed = _loan.amountBorrowed;
        period = _loan.period;
        dailyInterest = _loan.dailyInterest;
        claimDeadline = _loan.claimDeadline;
        startDate = _loan.startDate;
        lastComputedDebt = _loan.lastComputedDebt;
        currentDebt = _calculateCurrentDebt(_loan);
        amountRepayed = _loan.amountRepayed;
        repaymentsLength = _loan.repaymentsLength;
        lastComputedDate = _loan.lastComputedDate;
        managerAddress = _loan.managerAddress;
    }

    function userLoansOld(address _userAddress, uint256 _loanId)
    external
    view
    returns (
        uint256 amountBorrowed,
        uint256 period,
        uint256 dailyInterest,
        uint256 claimDeadline,
        uint256 startDate,
        uint256 currentDebt,
        uint256 lastComputedDebt,
        uint256 amountRepayed,
        uint256 repaymentsLength,
        uint256 lastComputedDate,
        address managerAddress
    )
    {
        _checkUserLoanOld(_userAddress, _loanId);

        WalletMetadata memory _metadata = _walletMetadata[_userAddress];
        LoanOld storage _loan = _usersOld[_metadata.userId].loans[_loanId];

        amountBorrowed = _loan.amountBorrowed;
        period = _loan.period;
        dailyInterest = _loan.dailyInterest;
        claimDeadline = _loan.claimDeadline;
        startDate = _loan.startDate;
        lastComputedDebt = _loan.lastComputedDebt;
        currentDebt = _calculateCurrentDebtOld(_loan);
        amountRepayed = _loan.amountRepayed;
        repaymentsLength = _loan.repayments.length;
        lastComputedDate = _loan.lastComputedDate;
        managerAddress = _loan.managerAddress;
//        managerAddress = address(0);
    }

    function userLoanRepayments(
        address _userAddress,
        uint256 _loanId,
        uint256 _repaymentId
    ) external view override returns (uint256 date, uint256 amount) {
        _checkUserLoan(_userAddress, _loanId);

        WalletMetadata memory _metadata = _walletMetadata[_userAddress];
        User storage _user = _users[_metadata.userId];
        Loan storage _loan = _user.loans[_loanId];

        require(_loan.repaymentsLength > _repaymentId, "Microcredit: Repayment doesn't exist");

        date = _loan.repayments[_repaymentId].date;
        amount = _loan.repayments[_repaymentId].amount;
    }

    function userLoanRepaymentsOld(
        address _userAddress,
        uint256 _loanId,
        uint256 _repaymentId
    ) external view returns (uint256 date, uint256 amount) {
        _checkUserLoanOld(_userAddress, _loanId);

        WalletMetadata memory _metadata = _walletMetadata[_userAddress];
        UserOld storage _user = _usersOld[_metadata.userId];
        LoanOld storage _loan = _user.loans[_loanId];

        require(_loan.repayments.length > _repaymentId, "Microcredit: Repayment doesn't exist");

        date = _loan.repayments[_repaymentId].date;
        amount = _loan.repayments[_repaymentId].amount;
    }

    function updateRevenueAddress(address _newRevenueAddress) external override onlyOwner {
        revenueAddress = _newRevenueAddress;
    }

    function updateDonationMiner(IDonationMiner _newDonationMiner) external override onlyOwner {
        donationMiner = _newDonationMiner;
    }

    /**
     * @notice Adds managers
     *
     * @param _managerAddresses      addresses of the managers
     */
    function addManagers(
        address[] calldata _managerAddresses,
        uint256[] calldata _currentLentAmountLimit
    ) external override onlyOwner {
        uint256 _length = _managerAddresses.length;
        uint256 _index;

        for (_index = 0; _index < _length; _index++) {
            _managerList.add(_managerAddresses[_index]);

            managers[_managerAddresses[_index]].currentLentAmountLimit = _currentLentAmountLimit[
            _index
            ];
            emit ManagerAdded(_managerAddresses[_index], _currentLentAmountLimit[_index]);
        }
    }

    /**
     * @notice Removes managers
     *
     * @param _managerAddresses     addresses of the managers
     */
    function removeManagers(address[] calldata _managerAddresses) external override onlyOwner {
        uint256 _length = _managerAddresses.length;
        uint256 _index;

        for (_index = 0; _index < _length; _index++) {
            _managerList.remove(_managerAddresses[_index]);
            emit ManagerRemoved(_managerAddresses[_index]);
        }
    }

    /**
     * @notice Adds a loan
     *
     * @param _userAddress           address of the user
     * @param _amount                amount of the loan
     * @param _period                period of the loan
     * @param _dailyInterest         daily interest of the loan
     * @param _claimDeadline         claim deadline of the loan
     */
    function addLoan(
        address _userAddress,
        uint256 _amount,
        uint256 _period,
        uint256 _dailyInterest,
        uint256 _claimDeadline
    ) external override onlyManagers {
        _addLoan(_userAddress, _amount, _period, _dailyInterest, _claimDeadline);
    }

    /**
     * @notice Adds multiples loans
     *
     * @param _userAddresses          addresses of the user
     * @param _amounts                amounts of the loan
     * @param _periods                periods of the loan
     * @param _dailyInterests         daily interests of the loan
     * @param _claimDeadlines         claim deadlines of the loan
     */
    function addLoans(
        address[] calldata _userAddresses,
        uint256[] calldata _amounts,
        uint256[] calldata _periods,
        uint256[] calldata _dailyInterests,
        uint256[] calldata _claimDeadlines
    ) external override onlyManagers {
        uint256 _loansNumber = _userAddresses.length;
        require(
            _loansNumber == _amounts.length,
            "Microcredit: calldata information arity mismatch"
        );
        require(
            _loansNumber == _periods.length,
            "Microcredit: calldata information arity mismatch"
        );
        require(
            _loansNumber == _dailyInterests.length,
            "Microcredit: calldata information arity mismatch"
        );
        require(
            _loansNumber == _claimDeadlines.length,
            "Microcredit: calldata information arity mismatch"
        );

        uint256 _index;

        for (_index = 0; _index < _loansNumber; _index++) {
            _addLoan(
                _userAddresses[_index],
                _amounts[_index],
                _periods[_index],
                _dailyInterests[_index],
                _claimDeadlines[_index]
            );
        }
    }

    /**
     * @notice Cancel a loan
     *
     * @param _userAddresses    User addresses
     * @param _loansIds Loan ids
     */
    function cancelLoans(address[] calldata _userAddresses, uint256[] calldata _loansIds)
    external
    override
    onlyManagers
    {
        require(
            _userAddresses.length == _loansIds.length,
            "Microcredit: calldata information arity mismatch"
        );

        uint256 _index;

        for (_index = 0; _index < _userAddresses.length; _index++) {
            _cancelLoan(_userAddresses[_index], _loansIds[_index]);
        }
    }

    /**
     * @notice Change user address
     *
     * @param _oldWalletAddress Old wallet address
     * @param _newWalletAddress New wallet address
     */
    function changeUserAddress(address _oldWalletAddress, address _newWalletAddress)
    external
    override
    onlyManagers
    {
        WalletMetadata storage _oldWalletMetadata = _walletMetadata[_oldWalletAddress];
        require(
            _oldWalletMetadata.userId > 0 && _oldWalletMetadata.movedTo == address(0),
            "Microcredit: This user cannot be moved"
        );

        WalletMetadata storage _newWalletMetadata = _walletMetadata[_newWalletAddress];
        require(_newWalletMetadata.userId == 0, "Microcredit: Target wallet address is invalid");

        _oldWalletMetadata.movedTo = _newWalletAddress;
        _newWalletMetadata.userId = _oldWalletMetadata.userId;

        _walletList.add(_newWalletAddress);

        emit UserAddressChanged(_oldWalletAddress, _newWalletAddress);
    }

    /**
     * @notice Claim a loan
     *
     * @param _loanId Loan ID
     */
    function claimLoan(uint256 _loanId) external override nonReentrant {
        _checkUserLoan(msg.sender, _loanId);

        WalletMetadata memory _metadata = _walletMetadata[msg.sender];
        User storage _user = _users[_metadata.userId];
        Loan storage _loan = _user.loans[_loanId];

        require(_loan.startDate == 0, "Microcredit: Loan already claimed");
        require(_loan.claimDeadline != 0, "Microcredit: Loan canceled");
        require(_loan.claimDeadline >= block.timestamp, "Microcredit: Loan expired");

        _loan.startDate = block.timestamp;

        _loan.lastComputedDebt = (_loan.amountBorrowed * (1e18 + _loan.dailyInterest / 100)) / 1e18;
        _loan.lastComputedDate = block.timestamp;

        cUSD.safeTransfer(msg.sender, _loan.amountBorrowed);

        emit LoanClaimed(msg.sender, _loanId);
    }

    /**
     * @notice Repay a loan
     *
     * @param _loanId Loan ID
     * @param _repaymentAmount Repayment amount
     */
    function repayLoan(uint256 _loanId, uint256 _repaymentAmount) external override nonReentrant {
        require(_repaymentAmount > 0, "Microcredit: Invalid amount");

        _checkUserLoan(msg.sender, _loanId);

        WalletMetadata memory _metadata = _walletMetadata[msg.sender];
        User storage _user = _users[_metadata.userId];
        Loan storage _loan = _user.loans[_loanId];

        require(_loan.startDate > 0, "Microcredit: Loan not claimed");
        require(_loan.lastComputedDebt > 0, "Microcredit: Loan has already been fully repayed");

        uint256 _currentDebt = _calculateCurrentDebt(_loan);

        if (_currentDebt < _repaymentAmount) {
            _repaymentAmount = _currentDebt;
        }

        if (_loan.amountRepayed + _repaymentAmount <= _loan.amountBorrowed) {
            //all repaymentAmount should go to microcredit address
            cUSD.safeTransferFrom(msg.sender, address(this), _repaymentAmount);
            _registerRepaymentToManager(_loan.managerAddress, _repaymentAmount);
        } else if (_loan.amountRepayed >= _loan.amountBorrowed) {
            //            all repaymentAmount should go to revenue address
            cUSD.safeTransferFrom(msg.sender, revenueAddress, _repaymentAmount);
        } else {
            //a part of the repayment should go to microcredit address and the rest should go to the revenue address

            uint256 _loanDiff = _loan.amountBorrowed - _loan.amountRepayed;

            if (revenueAddress == address(0)) {
                cUSD.safeTransferFrom(msg.sender, address(this), _repaymentAmount);
            } else {
                cUSD.safeTransferFrom(msg.sender, address(this), _loanDiff);
                cUSD.safeTransferFrom(msg.sender, revenueAddress, _repaymentAmount - _loanDiff);
            }

            _registerRepaymentToManager(_loan.managerAddress, _loanDiff);
        }

        Repayment storage _repayment = _loan.repayments[_loan.repaymentsLength];
        _loan.repaymentsLength++;
        _repayment.date = block.timestamp;
        _repayment.amount = _repaymentAmount;

        _loan.lastComputedDebt = _currentDebt - _repaymentAmount;
        _loan.amountRepayed += _repaymentAmount;

        uint256 _days = (block.timestamp - _loan.lastComputedDate) / 86400; //86400 = 1 day in seconds

        _loan.lastComputedDate = _loan.lastComputedDate + _days * 86400;

        if (_loan.lastComputedDebt == 0 && address(donationMiner) != address(0)) {
            donationMiner.donateVirtual(_loan.amountRepayed - _loan.amountBorrowed, msg.sender);
        }

        emit RepaymentAdded(msg.sender, _loanId, _repaymentAmount, _loan.lastComputedDebt);
    }

    /**
     * @notice Changes the borrowers manager address
     * @dev This method doesn't change anything on the contract state, it just emits events to be used by the off-chain system
     *
     * @param _borrowerAddresses address of the borrowers
     * @param _managerAddress address of the new manager
     */
    function changeManager(address[] memory _borrowerAddresses, address _managerAddress)
    external
    override
    onlyManagers
    {
        //todo: allocate loan to manager; not the user
        uint256 _index;
        require(_managerList.contains(_managerAddress), "Microcredit: invalid manager address");

        for (_index = 0; _index < _borrowerAddresses.length; _index++) {
            require(
                _walletList.contains(_borrowerAddresses[_index]),
                "Microcredit: invalid borrower address"
            );
            emit ManagerChanged(_borrowerAddresses[_index], _managerAddress);
        }
    }

    /**
     * @notice Transfers an amount of an ERC20 from this contract to an address
     *
     * @param _token address of the ERC20 token
     * @param _to address of the receiver
     * @param _amount amount of the transaction
     */
    function transferERC20(
        IERC20 _token,
        address _to,
        uint256 _amount
    ) external override nonReentrant onlyOwner {
        _token.safeTransfer(_to, _amount);
    }

    function _checkUserLoan(address _userAddress, uint256 _loanId) internal view {
        WalletMetadata memory _metadata = _walletMetadata[_userAddress];

        require(
            _metadata.userId > 0 && _metadata.movedTo == address(0),
            "Microcredit: Invalid wallet address"
        );

        User storage _user = _users[_metadata.userId];

        require(_user.loansLength > _loanId, "Microcredit: Loan doesn't exist");
    }


    function _checkUserLoanOld(address _userAddress, uint256 _loanId) internal view {
        WalletMetadata memory _metadata = _walletMetadata[_userAddress];

        require(
            _metadata.userId > 0 && _metadata.movedTo == address(0),
            "Microcredit: Invalid wallet address"
        );

        UserOld storage _user = _usersOld[_metadata.userId];

        require(_user.loans.length > _loanId, "Microcredit: Loan doesn't exist");
    }

    function _calculateCurrentDebt(Loan storage _loan) internal view returns (uint256) {
        if (_loan.lastComputedDebt == 0) {
            return 0;
        }

        uint256 _days = (block.timestamp - _loan.lastComputedDate) / 86400; //86400 = 1 day in seconds

        uint256 _currentDebt = _loan.lastComputedDebt;

        while (_days > 0) {
            _currentDebt = (_currentDebt * (1e18 + _loan.dailyInterest / 100)) / 1e18;
            _days--;
        }

        return _currentDebt;
    }

    function _calculateCurrentDebtOld(LoanOld storage _loan) internal view returns (uint256) {
        if (_loan.lastComputedDebt == 0) {
            return 0;
        }

        uint256 _days = (block.timestamp - _loan.lastComputedDate) / 86400; //86400 = 1 day in seconds

        uint256 _currentDebt = _loan.lastComputedDebt;

        while (_days > 0) {
            _currentDebt = (_currentDebt * (1e18 + _loan.dailyInterest / 100)) / 1e18;
            _days--;
        }

        return _currentDebt;
    }

    function _addLoan(
        address _userAddress,
        uint256 _amount,
        uint256 _period,
        uint256 _dailyInterest,
        uint256 _claimDeadline
    ) internal {
        require(_claimDeadline > block.timestamp, "Microcredit: invalid claimDeadline");

        WalletMetadata storage _metadata = _walletMetadata[_userAddress];
        require(_metadata.movedTo == address(0), "Microcredit: The user has been moved");

        Manager storage _manager = managers[msg.sender];
        require(
            _manager.currentLentAmount + _amount <= _manager.currentLentAmountLimit,
            "Microcredit: Manager don't have enough funds to borrow this amount"
        );

        if (_metadata.userId == 0) {
            _usersLength++;
            _metadata.userId = _usersLength;
            _walletList.add(_userAddress);
        }

        User storage _user = _users[_metadata.userId];

        uint256 _loansLength = _user.loansLength;

        if (_loansLength > 0) {
            Loan storage _previousLoan = _user.loans[_loansLength - 1];
            require(
                (_previousLoan.startDate > 0 && _previousLoan.lastComputedDebt == 0) || // loan claimed and fully paid
                (_previousLoan.startDate == 0 &&
                    _previousLoan.claimDeadline < block.timestamp) || //loan unclaimed and expired
                (_previousLoan.claimDeadline == 0), //loan canceled
                "Microcredit: The user already has an active loan"
            );
        }

        Loan storage _loan = _user.loans[_loansLength];
        _user.loansLength++;

        _loan.amountBorrowed = _amount;
        _loan.period = _period;
        _loan.dailyInterest = _dailyInterest;
        _loan.claimDeadline = _claimDeadline;
        _loan.managerAddress = msg.sender;

        _manager.currentLentAmount += _amount;

        emit LoanAdded(
            _userAddress,
            _loansLength,
            _amount,
            _period,
            _dailyInterest,
            _claimDeadline
        );
    }

    function _cancelLoan(address _userAddress, uint256 _loanId) internal {
        _checkUserLoan(_userAddress, _loanId);

        WalletMetadata memory _metadata = _walletMetadata[_userAddress];
        User storage _user = _users[_metadata.userId];
        Loan storage _loan = _user.loans[_loanId];

        require(_loan.startDate == 0, "Microcredit: Loan already claimed");
        require(_loan.claimDeadline != 0, "Microcredit: Loan already canceled");

        _loan.claimDeadline = 0; //set claimDeadline to 0 to prevent claiming (cancel the loan)

        Manager storage _manager = managers[_loan.managerAddress];

        _manager.currentLentAmount -= _loan.amountBorrowed;

        emit LoanCanceled(_userAddress, _loanId);
    }

    function _registerRepaymentToManager(address _managerAddress, uint256 _repaymentAmount)
    internal
    {
        if (_managerAddress != address(0)) {
            if (managers[_managerAddress].currentLentAmount > _repaymentAmount) {
                managers[_managerAddress].currentLentAmount -= _repaymentAmount;
            } else {
                managers[_managerAddress].currentLentAmount = 0;
            }
        }
    }

    // owner methods; to be deleted
    function copy1View(uint256 _start, uint256 _end, uint256 _return) external view onlyAdmin returns(uint256) {
        uint256 _userId;
        uint256 _loanId;
        uint256 _repaymentId;

        if (_return == 1) {
            return _return;
        }

        for (_userId = _start; _userId <= _end; _userId++) {
            if (_return == 2) {
                return _return;
            }

            UserOld memory _userOld = _usersOld[_userId];

            if (_return == 3) {
                return _return;
            }

            for (_loanId = 0; _loanId < _userOld.loans.length; _loanId++) {
                if (_return == 4) {
                    return _return;
                }

                LoanOld memory _loanOld = _userOld.loans[_loanId];

                if (_return == 5) {
                    return _return;
                }


                for (
                    _repaymentId = 0;
                    _repaymentId < _loanOld.repayments.length;
                    _repaymentId++
                ) {
                    if (_return == 6) {
                        return _return;
                    }
                    Repayment memory _repaymentOld = _loanOld.repayments[_repaymentId];

                    if (_return == 7) {
                        return _return;
                    }
                }
            }
        }

        return _return;
    }

    // owner methods; to be deleted
    function copy1(uint256 _start, uint256 _end) external onlyAdmin {
        uint256 _userId;
        uint256 _loanId;
        uint256 _repaymentId;


        for (_userId = _start; _userId <= _end; _userId++) {
            User storage _user = _users[_userId];
            UserOld memory _userOld = _usersOld[_userId];

            _user.loansLength = _userOld.loans.length;

            for (_loanId = 0; _loanId < _user.loansLength; _loanId++) {
                Loan storage _loan = _user.loans[_loanId];
                LoanOld memory _loanOld = _userOld.loans[_loanId];

                _loan.amountBorrowed = _loanOld.amountBorrowed;
                _loan.period = _loanOld.period;
                _loan.dailyInterest = _loanOld.dailyInterest;
                _loan.claimDeadline = _loanOld.claimDeadline;
                _loan.startDate = _loanOld.startDate;
                _loan.lastComputedDebt = _loanOld.lastComputedDebt;
                _loan.amountRepayed = _loanOld.amountRepayed;
                _loan.repaymentsLength = _loanOld.repayments.length;
                _loan.lastComputedDate = _loanOld.lastComputedDate;

                for (
                    _repaymentId = 0;
                    _repaymentId < _loan.repaymentsLength;
                    _repaymentId++
                ) {
                    Repayment storage _repayment = _loan.repayments[_repaymentId];
                    Repayment memory _repaymentOld = _loanOld.repayments[_repaymentId];

                    _repayment.date = _repaymentOld.date;
                    _repayment.amount = _repaymentOld.amount;
                }
            }
        }
    }

    function repayLoan2(address _borrowerAddress, uint256 _loanId, uint256 _repaymentId) external onlyAdmin {
        WalletMetadata memory _metadata = _walletMetadata[_borrowerAddress];

        Loan storage _loan = _users[_metadata.userId].loans[_loanId];
        LoanOld memory _loanOld = _usersOld[_metadata.userId].loans[_loanId];

        Repayment storage _repayment = _loan.repayments[_repaymentId];
        Repayment memory _repaymentOld = _loanOld.repayments[_repaymentId];

        _repayment.date = _repaymentOld.date;
        _repayment.amount = _repaymentOld.amount;

        _loan.repaymentsLength++;
        _loan.lastComputedDebt = _loanOld.lastComputedDebt;
        _loan.lastComputedDate = _loanOld.lastComputedDate;
        _loan.amountRepayed = _loanOld.amountRepayed;
    }

    function setManagers(address[] calldata _userAddresses, uint256[] calldata _loanIds, address[] calldata _managersAddresses)
    external
    onlyOwner
    {
        require(
            _userAddresses.length == _managersAddresses.length,
            "Microcredit: calldata information arity mismatch"
        );

        uint256 _index;

        for (_index = 0; _index < _userAddresses.length; _index++) {
            WalletMetadata memory _metadata = _walletMetadata[_userAddresses[_index]];

            _users[_metadata.userId].loans[_loanIds[_index]].managerAddress = _managersAddresses[_index];
        }
    }
}
