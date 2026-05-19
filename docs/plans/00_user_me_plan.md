# 00_user_me_plan.md

기준일: 2026-05-19  
구현 단계: `04_IMPLEMENTATION_ORDER.md` 1단계  
사전 문서: `docs/research/00_project_baseline_research.md`

---

## 1. 작업 목표

- `GET /api/users/me`의 응답을 현재 String에서 JSON으로 교체한다.
- 응답에 password를 포함하지 않는다.
- 함께 확인된 코드 규칙 위반 3건과 코드 품질 이슈 1건을 수정한다.

---

## 2. 수정할 파일 목록

| 파일 | 수정 내용 |
|------|-----------|
| `domain/user/entity/UserEntity.java` | `@Data` → `@Getter` 교체, `@Table(name = "user")` → `"users"` 변경 |
| `domain/user/repository/UserRepository.java` | 미사용 import `ResponseBody` 제거 |
| `global/security/JwtTokenProvider.java` | 중복 `@Component` 제거 (3번 줄 삭제) |
| `domain/user/controller/UserController.java` | `me()` 반환 타입을 `ResponseEntity<UserMeResponse>`로 변경, 서비스 위임 |
| `domain/user/service/UserService.java` | `getMe(String email)` 메서드 추가 |

---

## 3. 새로 만들 파일 목록

| 파일 | 내용 |
|------|------|
| `domain/user/dto/UserMeResponse.java` | `/api/users/me` 전용 응답 DTO |

---

## 4. 수정하지 말아야 할 파일

- `global/security/SecurityConfig.java`
- `global/security/JwtAuthenticationFilter.java`
- `domain/user/service/CustomUserDetailsService.java`
- `domain/user/dto/UserSignupRequest.java`
- `domain/user/dto/UserLoginRequest.java`
- `domain/user/dto/UserLoginResponse.java`
- `global/swagger/SwaggerConfig.java`
- `global/basetime/BaseTime.java`
- `domain/user/entity/Role.java`
- `CheckmateApplication.java`
- `build.gradle`
- `application.properties`

---

## 5. 각 수정이 필요한 이유

### UserEntity — `@Data` → `@Getter`
CLAUDE.md "Entity: @Data 금지". `@Data`는 `@Setter`, `@EqualsAndHashCode`, `@ToString`을 포함한다. Entity에서 `@Setter` 노출은 외부에서 필드를 자유롭게 변경할 수 있게 하므로 위험하다. `@EqualsAndHashCode`는 Hibernate 프록시 환경에서 id 기반 동등성 비교가 오작동할 수 있다. `@Getter`만 남기고 나머지는 제거한다. 기존에 명시된 `@NoArgsConstructor`, `@AllArgsConstructor`, `@Builder`는 유지한다.

### UserEntity — `@Table(name = "user")` → `"users"`
`02_DB_DESIGN.md` "예약어 테이블명 금지". `user`는 MySQL 예약어이며, DB_DESIGN.md의 테이블 목록도 `users`로 정의되어 있다. 방치하면 MySQL에서 SQL 구문 오류가 발생한다.

### UserRepository — `ResponseBody` import 제거
Repository 인터페이스에 `org.springframework.web.bind.annotation.ResponseBody`가 import되어 있다. 사용되지 않으며 web 레이어 의존이 잘못된 레이어에 포함된 것이다.

### JwtTokenProvider — `@Component` 중복 제거
`@Component`가 3번 줄과 14번 줄에 두 번 선언되어 있다. 중복 애너테이션은 동작에는 영향 없으나 코드 오염이므로 3번 줄을 제거한다.

### UserController — `me()` 수정 + UserService 위임
현재 String 반환 → JSON 반환으로 교체가 목적이다. CLAUDE.md "Controller: 로직 금지"에 따라 Controller는 서비스를 위임하고 응답만 반환한다. 조회 로직은 `UserService.getMe()`로 이동한다.

### UserService — `getMe()` 추가
email로 `UserEntity`를 조회하고 `UserMeResponse`로 변환하는 책임은 Service에 있다. 읽기 전용 쿼리이므로 `@Transactional(readOnly = true)` 적용 (클래스 레벨 `@Transactional` 오버라이드).

---

## 6. UserMeResponse DTO 설계

```java
package com.example.checkmate.domain.user.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;

@Getter
@AllArgsConstructor
public class UserMeResponse {
    private Long id;
    private String email;
    private String name;
    private String nickname;
    private String role;
}
```

- `password` 미포함 (보안 규칙).
- `record` 미사용 (CLAUDE.md "DTO: record 금지").
- `@Data` 미사용 (응답 전용이므로 Setter 불필요, `@Getter`만으로 충분).

---

## 7. `/api/users/me` 응답 JSON 예시

```json
{
  "id": 1,
  "email": "test@test.com",
  "name": "유환빈",
  "nickname": "hwanbin",
  "role": "ROLE_USER"
}
```

---

## 8. 빌드 검증 방법

Windows PowerShell:
```powershell
./gradlew.bat clean build
```

빌드 성공 기준: `BUILD SUCCESSFUL` 출력, 컴파일 오류 없음.

---

## 9. Swagger 테스트 순서

1. 서버 기동 후 `http://localhost:8080/swagger-ui/index.html` 접속.
2. `POST /api/users/signup` 실행 (email, password, name, nickname 입력).
3. `POST /api/users/login` 실행 → 응답의 `accessToken` 복사.
4. Swagger 상단 `Authorize` 버튼 클릭 → `Bearer {accessToken}` 입력.
5. `GET /api/users/me` 실행 → 아래 응답 확인:
   - HTTP 200
   - body: `{ id, email, name, nickname, role }` (password 없음)

---

## 10. 실패 케이스

| 케이스 | 예상 HTTP | 이유 |
|--------|-----------|------|
| Authorization 헤더 없이 요청 | 403 | SecurityConfig `anyRequest().authenticated()` |
| 만료/위조된 토큰으로 요청 | 403 | `JwtTokenProvider.validateToken()` 실패, SecurityContext 미설정 |
| 토큰 정상이나 DB에 해당 email 없음 | 404 | `UserService.getMe()` → `orElseThrow` 발동 |

---

## 11. 위험 요소와 주의점

### `@Table(name = "users")` 변경과 기존 DB 테이블
이미 `user`로 테이블이 생성된 DB 환경이 있다면, 이름 변경 후 기존 데이터에 접근 불가. 개발 환경에서 `ddl-auto`가 `create` 또는 `create-drop`이라면 자동 재생성되므로 문제없다. `update` 또는 `validate` 환경이라면 직접 `ALTER TABLE user RENAME TO users;` 실행 필요.

### `@Data` 제거 후 Setter 사라짐
`@Data` 제거로 모든 setter가 사라진다. 현재 코드에서 `UserEntity` setter를 직접 호출하는 곳이 있다면 컴파일 오류가 발생한다. `UserEntity.createUser()` 팩토리 메서드를 통해 생성하는 현재 패턴에서는 setter 직접 호출이 없으므로 문제없다. 빌드 실패 시 이 지점을 먼저 확인한다.

### `UserService.login()` 트랜잭션
클래스 레벨 `@Transactional`이 `login()`에도 적용되어 있다. `getMe()` 추가 시 `@Transactional(readOnly = true)`를 명시해 읽기 최적화를 적용한다. `signup()`의 메서드 레벨 중복 `@Transactional`은 이번 scope에서 건드리지 않는다.

### Authentication이 null인 경우
`/api/users/me`는 SecurityConfig에서 `authenticated()` 보호 중이므로, 인증되지 않은 요청은 필터 단계에서 차단된다. Controller 메서드까지 도달했다면 `Authentication`이 null일 수 없다. null 방어 코드는 추가하지 않는다.
