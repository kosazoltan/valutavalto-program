package com.puzzleir.backend.errorlog;

import lombok.*;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ErrorReportRequest {
    private String errorType;
    private String message;
    private String stack;
    private String url;
    private String requestId;
    private String requestMethod;
    private String requestBody;
    private String userId;
    private String userEmail;
    private String browser;
    private String commitSha;
    private String timestamp;
    private String severity;
    private Object breadcrumbs; // JSON array
}
