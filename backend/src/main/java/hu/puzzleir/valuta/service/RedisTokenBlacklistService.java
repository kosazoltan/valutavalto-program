package hu.puzzleir.valuta.service;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.stereotype.Service;

import java.time.Duration;
import java.time.Instant;
import java.util.concurrent.TimeUnit;

/**
 * Redis-alapu JWT token blacklist (vezerlokonyv par.12.5).
 *
 * A tokenId (JTI) a Redis kulcs, value: "revoked". TTL = a token hatralevo
 * elettartama. Automatikus tisztitas, nem kell cron.
 *
 * Aktivacio: redis.enabled=true a application.properties-ben.
 */
@Service("redisTokenBlacklistService")
@ConditionalOnProperty(name = "redis.enabled", havingValue = "true")
@RequiredArgsConstructor
@Slf4j
public class RedisTokenBlacklistService {

    private static final String KEY_PREFIX = "jwt:blacklist:";
    private static final String REVOKED_VALUE = "revoked";

    private final RedisTemplate<String, Object> redisTemplate;

    public void blacklist(String tokenId, Instant expiresAt) {
        if (tokenId == null || tokenId.isBlank()) return;
        Duration ttl = Duration.between(Instant.now(), expiresAt);
        if (ttl.isNegative() || ttl.isZero()) {
            log.debug("Token mar lejart, nem kerul blacklistre: {}", tokenId);
            return;
        }
        String key = KEY_PREFIX + tokenId;
        redisTemplate.opsForValue().set(key, REVOKED_VALUE, ttl.getSeconds(), TimeUnit.SECONDS);
        log.debug("Token blacklistre kerult: {} TTL={}s", tokenId, ttl.getSeconds());
    }

    public boolean isBlacklisted(String tokenId) {
        if (tokenId == null) return false;
        Boolean exists = redisTemplate.hasKey(KEY_PREFIX + tokenId);
        return Boolean.TRUE.equals(exists);
    }
}
