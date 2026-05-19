# 01_point_research.md

기준일: 2026-05-19  
작업 단계: `04_IMPLEMENTATION_ORDER.md` 2단계

---

## 1. 비즈니스 규칙 정리 (01_BUSINESS_RULES.md)

- 회원가입 시 100,000P 자동 지급.
- 잔액은 `PointWallet`에 보관, 모든 변동(입출금)은 `PointLedger`에 기록.
- 차감은 음수, 지급/환불은 양수.
- LedgerType: `SIGNUP_BONUS`, `TEST_CHARGE`, `ROOM_STAKE`, `ROOM_SETTLEMENT_REWARD`, `ROOM_REFUND`.
- `PointWallet` 수정 시 `PointLedger` 누락 금지 (CLAUDE.md 금지 규칙).

---

## 2. DB 스키마 분석 (02_DB_DESIGN.md)

### point_wallets
| 컬럼 | 타입 | 제약 |
|------|------|------|
| id | PK | AUTO |
| user_id | FK → users.id | UNIQUE |
| balance | BIGINT | NOT NULL |
| version | BIGINT | - (Optimistic Lock) |
| created_at | TIMESTAMP | - |
| updated_at | TIMESTAMP | - |

→ `created_at` / `updated_at` 둘 다 있으므로 `BaseTime` 상속 가능.  
→ `version` 은 `@Version` (Optimistic Lock). 동시 충전/차감 충돌 방지 목적.

### point_ledgers
| 컬럼 | 타입 | 제약 |
|------|------|------|
| id | PK | AUTO |
| user_id | FK → users.id | NOT NULL |
| room_id | FK → rooms.id | NULL 허용 |
| amount | BIGINT | NOT NULL (양수/음수) |
| balance_after | BIGINT | NOT NULL |
| type | VARCHAR (ENUM) | NOT NULL |
| description | VARCHAR | NULL 허용 |
| created_at | TIMESTAMP | - |

→ `updated_at` 없음. Ledger는 불변 → `BaseTime` 상속 불가.  
→ `@EntityListeners(AuditingEntityListener.class)` + `@CreatedDate` 직접 선언.  
→ `room_id`는 NULL 허용. Room 도메인 미구현 단계에서는 `Long roomId` 컬럼으로만 선언.

---

## 3. API 스펙 분석 (03_API_SPEC.md)

| 메서드 | URL | 설명 |
|--------|-----|------|
| GET | `/api/points/me` | 내 포인트 잔액 조회 |
| GET | `/api/points/me/ledgers` | 내 포인트 이력 조회 |
| POST | `/api/points/test/charge` | 테스트 충전 |

모두 인증 필요. SecurityConfig `anyRequest().authenticated()` 로 이미 보호됨.

---

## 4. 현재 UserService.signup 구조 분석

```
UserService.signup(UserSignupRequest)
  ├─ [1] 이메일 중복 검사 → existsByEmail()
  ├─ [2] 비밀번호 BCrypt 암호화
  ├─ [3] UserEntity.createUser() 팩토리 메서드 호출
  └─ [4] userRepository.save(user) → DB 저장
```

- 클래스 레벨 `@Transactional` + 메서드 레벨 `@Transactional` 중복 선언 상태 (이전 분석에서 확인).
- **PointWallet / PointLedger 생성 로직 없음** → 이번 단계에서 추가 필요.
- `userRepository.save(user)` 호출 후 `user` 객체에 id가 채워짐(Hibernate 즉시 flush).
  → 이 `user` 객체를 그대로 PointWallet 생성에 전달 가능.

---

## 5. 기존 코드 패턴 분석

### Entity 패턴 (UserEntity 기준)
- `@NoArgsConstructor(access = AccessLevel.PROTECTED)` — JPA 기본 생성자
- `@Getter` — `@Data` 미사용 (CLAUDE.md 규칙)
- `@Builder` 또는 static factory method
- 외부 직접 생성자 노출 금지 → factory method 사용

### Service 패턴
- `@Service @Transactional @RequiredArgsConstructor`
- 읽기 전용 메서드: `@Transactional(readOnly = true)` 명시
- email로 사용자 조회 후 처리

### Controller 패턴
- `@RestController @RequestMapping @RequiredArgsConstructor`
- 로직 없음 — Service 위임 후 ResponseEntity 반환
- 인증 필요 엔드포인트: `Authentication authentication` 파라미터로 email 추출

### DTO 패턴
- request: `@Getter @NoArgsConstructor` + validation 애너테이션
- response: `@Getter @AllArgsConstructor`
- record 금지 (CLAUDE.md)

---

## 6. 설계 결정 사항

### PointWallet balance 업데이트 방식
- Wallet에 `addBalance(long amount)` 메서드만 추가 (이번 단계는 충전만 있음).
- 차감 메서드는 Step 5 (Stake) 때 추가. 미리 만들지 않음 (CLAUDE.md: 요청받지 않은 기능 금지).

### SIGNUP_BONUS 처리 흐름
```
signup() 트랜잭션 안에서:
  user = userRepository.save(user)          // [1] user 저장 (id 확정)
  pointService.createInitialWallet(user)    // [2] wallet(0P) 생성 + ledger(+100000) 기록 + wallet balance 100000으로 업데이트
```
- `PointService.createInitialWallet()` 는 별도 `@Transactional` 없이 REQUIRED 전파로 UserService 트랜잭션에 참여.
- 원자성 보장: user + wallet + ledger 모두 같은 트랜잭션에서 커밋.

### room_id 처리 (PointLedger)
- 이번 단계(SIGNUP_BONUS, TEST_CHARGE)는 room 없음 → `Long roomId` nullable 필드로 선언.
- Room 구현(Step 3~) 시 `@ManyToOne` 관계 추가. 컬럼명은 `room_id`로 유지.

### PointService ← UserRepository 직접 주입
- PointService가 email로 사용자를 조회해야 하므로 `UserRepository` 직접 주입.
- UserService → PointService (단방향), PointService는 UserService를 호출하지 않음 → 순환 의존 없음.

---

## 7. 잠재적 이슈

| 이슈 | 내용 | 대응 |
|------|------|------|
| 기존 가입 사용자 PointWallet 없음 | 이미 가입한 계정은 Wallet이 없음 | 개발 환경이므로 DB 재생성 또는 수동 insert. 코드로 처리하지 않음 |
| Optimistic Lock 충돌 | 동시 charge 요청 시 version 충돌 | 이번 단계에서는 TEST_CHARGE 단일 요청만 고려. 예외 처리 불필요 |
| PointLedger @CreatedDate | BaseTime 미상속 시 AuditingEntityListener 직접 선언 필요 | `@EntityListeners` 명시로 해결. `@EnableJpaAuditing`은 이미 CheckmateApplication에 선언됨 |
