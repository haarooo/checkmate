package com.example.checkmate.global.storage;

import lombok.AllArgsConstructor;
import lombok.Getter;

@Getter
@AllArgsConstructor
public class FileUploadResult {
    private String fileUrl;
    private String originalName;
    private String storedName;
    private long size;
    private String contentType;
}
