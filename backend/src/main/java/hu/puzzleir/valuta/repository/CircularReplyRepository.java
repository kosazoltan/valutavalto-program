package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.CircularReply;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface CircularReplyRepository extends JpaRepository<CircularReply, Long> {

    /**
     * Defense-in-depth: a hívó findOrThrow-ja már cég-szűrt, de a query is
     * companyId-t követel (invariáns #1 — más cég válasza SOHA nem szivárog).
     */
    @Query("SELECT r FROM CircularReply r WHERE r.circular.id = :circularId " +
           "AND r.companyId = :companyId ORDER BY r.createdAt ASC")
    List<CircularReply> findByCircularIdAndCompanyId(
            @Param("circularId") Long circularId,
            @Param("companyId") UUID companyId);
}
