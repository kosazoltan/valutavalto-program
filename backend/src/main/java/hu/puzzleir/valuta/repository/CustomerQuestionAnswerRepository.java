package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.CustomerQuestionAnswer;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface CustomerQuestionAnswerRepository extends JpaRepository<CustomerQuestionAnswer, UUID> {

    /**
     * Upsert-kulcs lekérés, transaction-höz kötött válasz.
     * FIGYELEM: derived query null paraméterrel SOSEM talál ("= NULL") —
     * null transactionId-ra a ...IsNull párját kell hívni (CLAUDE.md JPQL-szabály).
     */
    Optional<CustomerQuestionAnswer> findByCompanyIdAndQuestionIdAndCustomerIdAndTransactionId(
            UUID companyId, UUID questionId, Long customerId, Long transactionId);

    /** Upsert-kulcs lekérés, tranzakció-független (transaction_id IS NULL) válasz. */
    Optional<CustomerQuestionAnswer> findByCompanyIdAndQuestionIdAndCustomerIdAndTransactionIdIsNull(
            UUID companyId, UUID questionId, Long customerId);

    /** Compliance-visszaolvasás ügyfelenként. */
    List<CustomerQuestionAnswer> findByCompanyIdAndCustomerIdOrderByAnsweredAtDesc(
            UUID companyId, Long customerId);

    /** Compliance-visszaolvasás kérdésenként. */
    List<CustomerQuestionAnswer> findByCompanyIdAndQuestionIdOrderByAnsweredAtDesc(
            UUID companyId, UUID questionId);
}
