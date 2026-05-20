package com.example.checkmate.global.storage;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.server.ResponseStatusException;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.Set;
import java.util.UUID;

@Service
public class LocalFileStorageService {

    private static final Set<String> ALLOWED_EXTENSIONS = Set.of(
            "jpg", "jpeg", "png", "gif", "webp", "mp4", "mov", "webm"
    );

    private final Path uploadDir;

    public LocalFileStorageService() {
        this.uploadDir = Paths.get(System.getProperty("user.dir"), "uploads", "proofs");
    }

    public FileUploadResult store(MultipartFile file) {
        if (file == null || file.isEmpty()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "파일이 비어 있습니다.");
        }

        String originalName = file.getOriginalFilename();
        if (originalName == null || originalName.isBlank()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "파일명이 없습니다.");
        }

        int dotIndex = originalName.lastIndexOf('.');
        if (dotIndex < 0) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "확장자가 없는 파일입니다.");
        }

        String extension = originalName.substring(dotIndex + 1).toLowerCase();
        if (!ALLOWED_EXTENSIONS.contains(extension)) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "허용되지 않는 파일 형식입니다.");
        }

        String contentType = file.getContentType();
        if (contentType != null && !contentType.startsWith("image/") && !contentType.startsWith("video/")) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "허용되지 않는 Content-Type입니다.");
        }

        String storedName = UUID.randomUUID().toString().replace("-", "") + "." + extension;
        String fileUrl = "/uploads/proofs/" + storedName;

        try {
            Files.createDirectories(uploadDir);
            Files.copy(file.getInputStream(), uploadDir.resolve(storedName));
        } catch (IOException e) {
            throw new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR, "파일 저장에 실패했습니다.");
        }

        return new FileUploadResult(fileUrl, originalName, storedName, file.getSize(), contentType);
    }
}
