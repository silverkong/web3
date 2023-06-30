// SPDX-License-Identifier: MIT
// low level 학습을 위한 코드입니다. 위험성이 높습니다.(Please use !!edu!! this code. This code have some vulnerability.)

/////////////////////////////////////////////////////////////
// Created By EunBeen (EunBeen Jung holds the copyright.)  //
// Creator E-mail : jungeb325@gmail.com                    //
//                                                         //
// Advisor : Sueun Cho (Bentley Cho)                       //
// Advisor E-mail : sueun.dev@gmail.com                    //
/////////////////////////////////////////////////////////////
pragma solidity ^0.8.18;

contract EunBeen_contract_assembly {
    //각 할당된 Random 256bit hash 값 (Assigned value of Random 256 bit hash)
    //이 해쉬값은 무작위로 추출을 한 상태입니다. (I made this hash using random function)
    uint256 constant SYMBOL_SLOT = 0x6d3179674f93bdaab83d38b37f7ef0d8f6163fa57b09800f5b2f65e981ecfde5;
    uint256 constant NAME_SLOT = 0x35f89a353ce56812b8b135f831696ea5deaba3838c6e3eeebc348fb8663c7efb;
    uint256 constant TOTAL_SUPPLY_SLOT = 0x20f912b660bc4fca980d0bf1850a77e9a5e335517c402b466854bbd11d2bd4ea;
    uint256 constant ALLOWANCES_SLOT = 0xc9b6368200db8ca1b1d6b0ee6b7e4a4b98c3d0190cf73a2c8f76fe0b63fb22d2;
    uint256 constant BALANCES_SLOT = 0x1f1c25292df029f1a1d0d61e3895f2359478a5f412df553fc09585e7f4092031;

    //Declare onwer (This owner is not used until now)
    address public owner;

    //constructor ERC20
    constructor() {
        //Declare onwer (This owner is not used until now)
        owner = msg.sender;
        assembly {
            //sstore 은 스토리지에 값을 저장하는 EVM 명령어. (storage store -> sstore)
            sstore(NAME_SLOT, "EunBeen")
            sstore(SYMBOL_SLOT, "EB")
        }
    }
    
    //ERC20 name
    function name() external view returns (string memory) {
        assembly {
            //storage load (sload) 를 하여 토큰의 이름을 나타냄
            let nameBytes := sload(NAME_SLOT)
            //선언 declare
            let nameLength
            //이름의 실제 길이를 찾음. if i is less than 32, true(lt)
            //이유는 EVM은 32바이트 단위로 데이터를 저장해서 이름이 32 바이트 미만인 경우만 찾아야 함
            for { let i := 0 } lt(i, 32) { i := add(i, 1) }
            {
                //만약 (shift left) shl 을 했을떄 0이라면 실행 아니면 for문으로 다시
                if iszero(shl(mul(add(i, 1), 0x08), nameBytes)) {
                    nameLength := add(i, 1)
                    break
                }
            }
            //mstore and mstore8(store 8 bit at once)
            mstore(0x60, nameBytes)
            mstore8(0x5f, nameLength)
            return(0x20, 0x60)
        }
    }
    
    function symbol() external view returns (string memory) {
        assembly {
            //코드는 name과 같은 원리
            let symbolBytes := sload(SYMBOL_SLOT)
            let symbolLength
            for { let i := 0 } lt(i, 32) { i := add(i, 1) }
            {
                if iszero(shl(mul(add(i, 1), 0x08), symbolBytes)) { 
                    symbolLength := add(i, 1)
                    break
                }
            }

            mstore(0x60, symbolBytes)
            mstore8(0x5f, symbolLength)
            return(0x20, 0x60)
        }
    }

    function totalSupply() external view returns (uint256 _totalSupply) {
        //storage load (sload) 로 totalSupply 가져옴
        assembly {
            _totalSupply := sload(TOTAL_SUPPLY_SLOT)
        }
    }

    function balanceOf(address account) external view returns (uint256 accountBalance) {
        assembly {
            //지역변수 선언
            let map_position := BALANCES_SLOT
            //위치를 찾는데 필요
            let offset := and(account, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
            //offset과 map_position을 더한 값을 index에 저장
            let index := add(map_position, offset)
            accountBalance := sload(index)
        }
    }

    function mint(address account, uint256 amount) external {
        assembly {
            let map_position := BALANCES_SLOT
            /* 
                아래 라인은 Ethereum 주소 (account)를 20바이트로 제한하기 위해 and 비트 연산을 사용하여 
                Ethereum 주소와 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF를 결합. 
                이는 Ethereum 주소를 스토리지 인덱스로 변환하는 데 사용.
            */
            let offset := and(account, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
            let index := add(map_position, offset)
            let current_balance := sload(index)
            let updated_balance := add(current_balance, amount)
            sstore(index, updated_balance)
            
            let current_total_supply := sload(TOTAL_SUPPLY_SLOT)
            let updated_total_supply := add(current_total_supply, amount)
            sstore(TOTAL_SUPPLY_SLOT, updated_total_supply)
        }
    }
}
