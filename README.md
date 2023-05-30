# FAYC

- onlyMinter Modifier를 적용하여 FAYC NFT에 접근을 FAYCSale로만 가능하게 제한해봤습니다.
- reveal기능을 활용하여 NFT 원본을 보존해봤습니다.
- MinterContract는 onlyOnwer만 조작이 가능합니다.
- FAYCSale은 주석과 컨트랙트가 일부 다를 수 있습니다.
- mintRole, WLmintRole을 분리해 화이트 리스트 일 경우 좀더 저렴한 가격으로 구입이 가능하게 해봤습니다. onlyCreator() 라는 모디파이어를 사용해 나중에 민팅이 끝나고 수익 분쟁을 없앴습니다.
- 이외에도 많은 기능이 탑재되어있습니다.