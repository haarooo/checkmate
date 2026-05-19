# 01_point_plan.md

기준일: 2026-05-19  
구현 단계: `04_IMPLEMENTATION_ORDER.md` 2단계  
사전 문서: `docs/research/01_point_research.md`

---

## 1. 작업 목표

- 회원가입 시 `PointWallet` 생성 + `PointLedger`(SIGNUP_BONUS +100,000P) 자동 기록.
- `GET /api/points/me` — 내 포인트 잔액 조회.
- `GET /api/points/me/ledgers` — 내 포인트 이력 조회.
- `POST /api/points/test/charge` — 테스트 충전 (양수 금액, PointLedger 기록).
- Room, Proof, Settlement 도메인 수정 없음.

---

## 2. 현재 UserService.signup 구조 분석

```
UserService.signup(UserSignupRequest)          // @Transactional (class + method 중복)
  ├─ existsByEmail → 중복 이메일 400 Bad Request
  ├─ BCrypt 암호화
  ├─ UserEntity.createUser() 팩토리 메서드
  └─ userRepository.save(user)
     └─ user.id 확정됨 (이 시점 이후 PointWallet 생성 가능)
     ※ PointWallet / PointLedger 생성 없음 → 이번 단계에서 추가
```

추가 위치: `userRepository.save(user)` 직후, 트랜잭션 종료 전.  
방식: `pointService.createInitialWallet(user)` 호출.

---

## 3. 새로 만들 파일

| 파일 | 위치 |
|------|------|
| `PointWallet.java` | `domain/point/entity/` |
| `PointLedger.java` | `domain/point/entity/` |
| `LedgerType.java` | `domain/point/entity/` |
| `PointWalletRepository.java` | `domain/point/repository/` |
| `PointLedgerRepository.java` | `domain/point/repository/` |
| `PointService.java` | `domain/point/service/` |
| `PointController.java` | `domain/point/controller/` |
| `PointWalletResponse.java` | `domain/point/dto/` |
| `PointLedgerResponse.java` | `domain/point/dto/` |
| `TestChargeRequest.java` | `domain/point/dto/` |

---

## 4. 수정할 파일

| 파일 | 변경 내용 |
|------|-----------|
| `domain/user/service/UserService.java` | `PointService` 주입 추가, `signup()` 끝에 `pointService.createInitialWallet(user)` 호출 추가 |

---

## 5. 수정하지 말아야 할 파일

- `global/security/SecurityConfig.java`
- `global/security/JwtAuthenticationFilter.java`
- `global/security/JwtTokenProvider.java`
- `domain/user/service/CustomUserDetailsService.java`
- `domain/user/controller/UserController.java`
- `domain/user/entity/UserEntity.java`
- `domain/user/entity/Role.java`
- `domain/user/dto/` (모든 User DTO)
- `domain/user/repository/UserRepository.java`
- `global/basetime/BaseTime.java`
- `global/swagger/SwaggerConfig.java`
- `CheckmateApplication.java`
- `build.gradle`
- `application.properties`

---

## 6. PointWallet Entity 설계

```java
package com.example.checkmate.domain.point.entity;

@NoArgsConstructor(access = AccessLevel.PROTECTED)
@Getter
@Entity
@Table(name = "point_wallets")
public class PointWallet extends BaseTime {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false, unique = true)
    private UserEntity user;

    @Column(nullable = false)
    private Long balance;

    @Version
    private Long version;

    public static PointWallet create(UserEntity user) {
        PointWallet wallet = new PointWallet();
        wallet.user = user;
        wallet.balance = 0L;
        return wallet;
    }

    public void addBalance(long amount) {
        this.balance += amount;
    }
}
```

- `BaseTime` 상속 (`created_at`, `updated_at` 둘 다 있음).
- `@Version` → Optimistic Lock (동시 잔액 변경 충돌 방지).
- `addBalance(long amount)` 만 제공 — 차감은 Step 5(Stake)에서 추가.
- `@Data` 미사용, Setter 미노출.

---

## 7. PointLedger Entity 설계

```java
package com.example.checkmate.domain.point.entity;

@NoArgsConstructor(access = AccessLevel.PROTECTED)
@Getter
@Entity
@Table(name = "point_ledgers")
@EntityListeners(AuditingEntityListener.class)
public class PointLedger {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private UserEntity user;

    @Column(name = "room_id")
    private Long roomId;          // nullable, Room 구현 전까지 Long으로 관리

    @Column(nullable = false)
    private Long amount;          // 양수=지급/환불, 음수=차감

    @Column(nullable = false)
    private Long balanceAfter;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private LedgerType type;

    private String description;

    @CreatedDate
    @Column(updatable = false)
    private LocalDateTime createdAt;

    public static PointLedger create(
            UserEntity user,
            long amount,
            long balanceAfter,
            LedgerType type,
            String description
    ) {
        PointLedger ledger = new PointLedger();
        ledger.user = user;
        ledger.roomId = null;
        ledger.amount = amount;
        ledger.balanceAfter = balanceAfter;
        ledger.type = type;
        ledger.description = description;
        return ledger;
    }
}
```

- `BaseTime` 미상속 — `updated_at` 없음, Ledger는 불변.
- `@EntityListeners(AuditingEntityListener.class)` 직접 선언 (BaseTime 없이도 `@CreatedDate` 작동).
- `roomId` 는 Long nullable — Room Entity 미존재 단계에서 `@ManyToOne` 미적용.
- `@Column(updatable = false)` on `createdAt` — Ledger 불변성 명시.

---

## 8. LedgerType enum 설계

```java
package com.example.checkmate.domain.point.entity;

public enum LedgerType {
    SIGNUP_BONUS,
    TEST_CHARGE,
    ROOM_STAKE,
    ROOM_SETTLEMENT_REWARD,
    ROOM_REFUND
}
```

- `01_BUSINESS_RULES.md` 명시 값 그대로 사용.
- Room 관련 타입(`ROOM_*`)은 사용하지 않지만 Enum에 선언만 해둠.

---

## 9. 회원가입 시 100,000P 지급 연결 방식

### 흐름
```
UserService.signup()  [기존 @Transactional 안에서]
  │
  ├─ [기존] userRepository.save(user)  → user.id 확정
  │
  └─ [추가] pointService.createInitialWallet(user)
               ├─ PointWallet.create(user)         → balance=0
               ├─ pointWalletRepository.save(wallet)
               ├─ PointLedger.create(user, +100000, 100000, SIGNUP_BONUS, "회원가입 보너스")
               ├─ pointLedgerRepository.save(ledger)
               └─ wallet.addBalance(100000)         → balance=100000
                  [Hibernate dirty checking → 트랜잭션 커밋 시 UPDATE 자동]
```

### UserService 변경 범위

```java
// 추가: PointService 주입
private final PointService pointService;

// signup() 마지막에 한 줄 추가
userRepository.save(user);
pointService.createInitialWallet(user);   // ← 이 줄만 추가
```

### 트랜잭션 전파
- `UserService.signup()` — `@Transactional` (기존)
- `PointService.createInitialWallet()` — `@Transactional` (REQUIRED 기본값)
- → 동일 트랜잭션 참여. user + wallet + ledger 원자적 커밋.

---

## 10. 포인트 잔액 조회 API 설계

```
GET /api/points/me
Authorization: Bearer {token}

응답 200:
{ "balance": 100000 }
```

**PointService.getMyWallet(String email)**
1. `userRepository.findByEmail(email)` → 없으면 404
2. `pointWalletRepository.findByUser(user)` → 없으면 404
3. `PointWalletResponse(wallet.getBalance())` 반환

**PointWalletResponse**
```java
@Getter @AllArgsConstructor
public class PointWalletResponse {
    private Long balance;
}
```

---

## 11. 포인트 이력 조회 API 설계

```
GET /api/points/me/ledgers
Authorization: Bearer {token}

응답 200:
[
  { "id": 1, "amount": 100000, "balanceAfter": 100000, "type": "SIGNUP_BONUS",
    "description": "회원가입 보너스", "createdAt": "2026-05-19T10:00:00" },
  ...
]
```

**PointService.getMyLedgers(String email)**
1. `userRepository.findByEmail(email)` → 없으면 404
2. `pointLedgerRepository.findByUserOrderByCreatedAtDesc(user)` → 최신순
3. `List<PointLedgerResponse>` 반환

**PointLedgerRepository 메서드**
```java
List<PointLedger> findByUserOrderByCreatedAtDesc(UserEntity user);
```

**PointLedgerResponse**
```java
@Getter @AllArgsConstructor
public class PointLedgerResponse {
    private Long id;
    private Long amount;
    private Long balanceAfter;
    private String type;
    private String description;
    private LocalDateTime createdAt;
}
```

---

## 12. 테스트 충전 API 설계

```
POST /api/points/test/charge
Authorization: Bearer {token}
Content-Type: application/json

요청:
{ "amount": 10000 }

응답 200:
{ "balance": 110000 }
```

**PointService.testCharge(String email, long amount)**
1. `userRepository.findByEmail(email)` → 없으면 404
2. `pointWalletRepository.findByUser(user)` → 없으면 404
3. `long newBalance = wallet.getBalance() + amount`
4. `PointLedger.create(user, amount, newBalance, TEST_CHARGE, "테스트 충전")`
5. `pointLedgerRepository.save(ledger)`
6. `wallet.addBalance(amount)` → dirty checking
7. `PointWalletResponse(wallet.getBalance())` 반환

**TestChargeRequest**
```java
@Getter @NoArgsConstructor
public class TestChargeRequest {
    @Min(value = 1, message = "충전 금액은 1 이상이어야 합니다.")
    private long amount;
}
```

---

## 13. 트랜잭션 처리 방식

| 메서드 | 트랜잭션 | 이유 |
|--------|----------|------|
| `createInitialWallet(user)` | `@Transactional` (REQUIRED) | UserService 트랜잭션 참여 |
| `getMyWallet(email)` | `@Transactional(readOnly = true)` | 읽기 최적화 |
| `getMyLedgers(email)` | `@Transactional(readOnly = true)` | 읽기 최적화 |
| `testCharge(email, amount)` | `@Transactional` | wallet 잔액 변경 포함 |

PointService 클래스 레벨 `@Transactional` 선언 없음 — 메서드마다 명시.

---

## 14. 실패 케이스

| 케이스 | HTTP | 발생 위치 |
|--------|------|-----------|
| 토큰 없이 요청 | 403 | SecurityConfig |
| 만료된 토큰 | 403 | JwtAuthenticationFilter |
| 잔액 조회 시 wallet 없음 | 404 | `PointService.getMyWallet()` |
| 이력 조회 시 wallet 없음 | 404 | `PointService.getMyLedgers()` |
| testCharge amount = 0 | 400 | `@Min(1)` validation |
| testCharge amount 음수 | 400 | `@Min(1)` validation |
| 회원가입 중 wallet 생성 실패 | 500 → 전체 롤백 | signup 트랜잭션 참여이므로 user도 롤백 |

---

## 15. 빌드 검증 방법

```powershell
./gradlew.bat clean build
```

성공 기준: `BUILD SUCCESSFUL`, 컴파일 오류 없음.

---

## 16. Swagger 테스트 순서

### 신규 가입 계정으로 테스트 (기존 계정은 Wallet 없음)

1. `POST /api/users/signup` → 새 이메일로 가입
2. `POST /api/users/login` → accessToken 추출
3. Swagger `Authorize` → `Bearer {token}` 입력
4. `GET /api/points/me` → `{ "balance": 100000 }` 확인
5. `GET /api/points/me/ledgers` → SIGNUP_BONUS 이력 1건 확인
6. `POST /api/points/test/charge` body: `{ "amount": 10000 }` → `{ "balance": 110000 }` 확인
7. `GET /api/points/me/ledgers` → SIGNUP_BONUS + TEST_CHARGE 이력 2건 확인
8. `GET /api/points/me` → `{ "balance": 110000 }` 재확인

### 주의
- 기존에 가입된 계정(이번 단계 이전 가입)은 PointWallet이 없으므로 `/api/points/me` 404 응답.
- 반드시 이번 단계 구현 이후 신규 가입한 계정으로 테스트해야 한다.
