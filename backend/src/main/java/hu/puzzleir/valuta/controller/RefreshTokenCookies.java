package hu.puzzleir.valuta.controller;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.http.HttpHeaders;
import org.springframework.http.ResponseCookie;

import java.time.Duration;

final class RefreshTokenCookies {

    private static final String COOKIE_NAME = "refreshToken";
    private static final String COOKIE_PATH = "/api/v1/auth";
    private static final String SAME_SITE = "Strict";
    private static final Duration REFRESH_TOKEN_MAX_AGE = Duration.ofDays(7);

    private RefreshTokenCookies() {
    }

    static void addRefreshToken(
            HttpServletResponse response,
            HttpServletRequest request,
            String rawRefreshToken) {
        response.addHeader(HttpHeaders.SET_COOKIE, refreshTokenCookie(request, rawRefreshToken).toString());
    }

    static void clearRefreshToken(HttpServletResponse response, HttpServletRequest request) {
        response.addHeader(HttpHeaders.SET_COOKIE, clearRefreshTokenCookie(request).toString());
    }

    private static ResponseCookie refreshTokenCookie(HttpServletRequest request, String rawRefreshToken) {
        return ResponseCookie.from(COOKIE_NAME, rawRefreshToken)
                .httpOnly(true)
                .secure(request.isSecure())
                .sameSite(SAME_SITE)
                .path(COOKIE_PATH)
                .maxAge(REFRESH_TOKEN_MAX_AGE)
                .build();
    }

    private static ResponseCookie clearRefreshTokenCookie(HttpServletRequest request) {
        return ResponseCookie.from(COOKIE_NAME, "")
                .httpOnly(true)
                .secure(request.isSecure())
                .sameSite(SAME_SITE)
                .path(COOKIE_PATH)
                .maxAge(0)
                .build();
    }
}
