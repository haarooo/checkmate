# 07_local_file_upload_research.md

## 분석 대상
LocalFileStorageService + WebConfig — 8단계 Proof Submit에서 사용할 파일 저장 레이어

## 기존 구조 확인
- global/ 하위: basetime, security, swagger 패키지 존재
- global/config/, global/storage/ 없음 → 신규 생성
- .gitignore에 uploads/ 없음 → 추가 필요

## 경로 전략
- 저장 위치: `{System.getProperty("user.dir")}/uploads/proofs/`
- WebConfig: `/uploads/**` → `file:{user.dir}/uploads/` 매핑
- SecurityConfig의 GET /uploads/** permitAll 필요하나, 사용자가 직접 처리 예정 — 이번 작업에서 SecurityConfig 수정 금지

## 허용 파일 정책
- 이미지: jpg, jpeg, png, gif, webp
- 동영상: mp4, mov, webm
- 검증 순서:
  1. 빈 파일 → 400
  2. originalFilename 비어있음 → 400
  3. 확장자 없음 → 400
  4. 확장자 허용 목록 미포함 → 400
  5. Content-Type 존재 시 image/ 또는 video/ 로 시작해야 함 → 400

## 반환 설계
- FileUploadResult: fileUrl, originalName, storedName, size, contentType
- fileUrl 형식: `/uploads/proofs/{storedName}`
- storedName: UUID + 원본 확장자

## 변경 범위
- 신규: `global/config/WebConfig.java`
- 신규: `global/storage/LocalFileStorageService.java`
- 신규: `global/storage/FileUploadResult.java`
- 수정: `.gitignore` (uploads/ 추가)
- SecurityConfig 수정 없음

## 제외
- Proof Entity/Controller/Submit 구현 금지
- S3, Presigned URL 금지
- build 폴더 / src/main/resources/static 저장 금지
