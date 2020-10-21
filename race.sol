pragma solidity ^0.6.10;

abstract contract DaoInterface {
    
    address public creator;
    address public curator;
    uint256 valuation;
    uint256 public totalBalance;
    uint256 public proposalCount;
    mapping ( address => uint256 ) balances;
    mapping ( uint256 => Proposal) public proposals;
    mapping (address => bool) allowedRecipients;
    mapping ( address => bool) membership;
    
    struct Proposal {
        address recipient;
        
        //amount to transfer to 'recipient' if the Proposal is accepted
        uint amount;
        string description;
        
        //true if the Proposal's votes have yet to be counted and sealed.
        bool isSealed;
        
        //true if the proposal is Finished. 
        bool isFinished;
        
        //numbers of tokens in favor of/opposed to the proposal
        uint yes;
        mapping (address => bool) votedYes;
        uint no;
        mapping ( address => bool) votedNo;
        
        address creator;
    }
    // use balance(-) change token(+) 
    function deposit() payable public virtual returns (bool success);
    
    //withdraw amount is the token amount
    function withdraw (uint amount) public virtual returns (bool success);
    
    function getBalance ()  public virtual returns (uint256 balance);
    
    function createProposal(address _recipient, uint _amount, string memory _descrption)  public virtual;
    
    function voteYes() public virtual;
    
    function voteNo() public virtual;
}


contract Dao is DaoInterface {
     constructor()  public {
        creator = msg.sender;
        curator = creator;
        totalBalance = 0;
        valuation = 10;
        proposalCount = 0;
        proposals[proposalCount].isFinished = true;
    } 
    
    modifier onlyMembership {
        require (membership[msg.sender] == true, "you need to be a membership");
        _;
    }
    
    modifier onlyCurator {
        require(msg.sender == curator);
        _;
    }
    
    function delegateCurator (address newCurator) onlyCurator public returns (bool success) {
        require( proposals[proposalCount].isSealed == false );
        curator = newCurator;
        success = true;
    }
    
    function deposit() payable public override returns (bool success){
        if ( proposals[proposalCount].votedYes[msg.sender]) {
            proposals[proposalCount].yes += msg.value / (valuation / 10);
        } else if ( proposals[proposalCount].votedNo[msg.sender] ) {
            proposals[proposalCount].no += msg.value / (valuation / 10);
        }
        
        balances[msg.sender] += msg.value / ( valuation / 10 ); 
        totalBalance += msg.value / ( valuation / 10 );
        membership[msg.sender] = true;
        return true;
        }
  
    //this is a vulnerable withdraw function
    function withdraw (uint amount) public override returns (bool success) {
        require ( amount <= balances[msg.sender] );
        require ( proposals[proposalCount].votedYes[msg.sender] == false );
        require ( proposals[proposalCount].votedNo[msg.sender] == false );
        
        //this is where the vulnerability lies
       if (!(msg.sender.call.value(amount* (valuation / 10)))){
           balances[msg.sender] -= amount;
           totalBalance -= amount;
       }
        
        //remedy1
        /*
        balances[msg.sender] -= amount;
        totalBalance -= amount;
        if (!(msg.sender.call.value(amount* (valuation / 10)))){
           
       }
        */
        
        if (balances[msg.sender] == 0){
            membership[msg.sender]=false;
        }
        return true;
    }
    
    function getBalance () public override returns (uint256 balance){
         return balances[msg.sender];
     }
     
    function createProposal(address _recipient, uint _amount, string memory _descrption)  public onlyCurator override{
         require (totalBalance >= _amount);
         require (proposals[proposalCount].isFinished);
         proposalCount++;
         
         proposals[proposalCount].recipient = _recipient;
         proposals[proposalCount].amount = _amount;
         proposals[proposalCount].description = _descrption;
         
         proposals[proposalCount].creator = curator;
         proposals[proposalCount].isSealed = false;
         proposals[proposalCount].isFinished = false;
     }
     
    function voteYes() onlyMembership public override {
         require( proposals[proposalCount].isSealed == false);
         
         proposals[proposalCount].yes += balances[msg.sender];
         proposals[proposalCount].votedYes[msg.sender] = true;
         
         if (proposals[proposalCount].yes > (totalBalance/2)){
            proposals[proposalCount].isSealed = true;
            uint256 randNum;
            randNum = rand(10);
            valuation = valuation * randNum;
            
            if (valuation == 0 ) {
                valuation = 10;
                totalBalance = 0;
                
                //how to make balance to be 0
            }
            
         }
     }
     
    function voteNo() onlyMembership public override {
         require(proposals[proposalCount].isSealed == false);
         proposals[proposalCount].no += balances[msg.sender];
         proposals[proposalCount].votedNo[msg.sender] = true;
         
         if (proposals[proposalCount].no > (totalBalance/2)){
             proposals[proposalCount].isSealed = true;
             proposals[proposalCount].isFinished = true;
         }
     }
     
    function rand(uint256 _length) public view returns(uint256) {  
        uint256 random = uint256(keccak256(abi.encodePacked(block.difficulty, now)));  
        return random%_length;  
    }  
}




