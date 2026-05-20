# 07_local_file_upload_plan.md

## 목표
LocalFileStorageService 구현 + WebConfig로 정적 파일 서빙 (API 엔드포인트 없음)

## 생성/수정 파일

### 1. FileUploadResult.java (`global/storage/`)
- 필드: fileUrl, originalName, storedName, size(long), contentType
- class + @Getter + @AllArgsConstructor

### 2. LocalFileStorageService.java (`global/storage/`)
- `store(MultipartFile file)` → FileUploadResult
- 검증 순서: 빈 파일 → originalFilename 없음 → 확장자 없음 → 확장자 불허 → Content-Type 불일치 (모두 400)
- 허용 확장자: jpg, jpeg, png, gif, webp, mp4, mov, webm (소문자 변환 후 비교)
- storedName = UUID + 원본 확장자
- 저장 경로: `{user.dir}/uploads/proofs/`, 디렉터리 없으면 Files.createDirectories 자동 생성
- 저장 실패 시 500

### 3. WebConfig.java (`global/config/`)
- WebMvcConfigurer 구현
- `/uploads/**` → `file:{user.dir}/uploads/` 매핑

### 4. .gitignore
- 맨 아래 `uploads/` 추가

## 불변 제약
- SecurityConfig 수정 금지 (GET /uploads/** permitAll은 사용자가 직접 처리)
- Proof Entity/Controller 구현 금지

## 검증
- `./gradlew.bat clean build` 성공까지만 확인
- 실제 업로드 테스트는 8단계 Proof Submit에서 진행
