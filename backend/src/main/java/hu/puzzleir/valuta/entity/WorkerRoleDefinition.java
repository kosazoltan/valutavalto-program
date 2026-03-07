package hu.puzzleir.valuta.entity;

import jakarta.persistence.*;
import lombok.*;

/**
 * Operatív szerepkör definíció (domain-specifikus).
 * 
 * 9 féle: CASHIER, COURIER, VAULT_KEEPER, CHIEF_VAULT,
 * REGIONAL_MGR, OFFICE_MGR, AUDITOR, SECURITY, DIRECTOR
 * 
 * Backward compat: a Worker.role enum (CASHIER/SUPERVISOR/MANAGER/ADMIN) MARAD!
 * Ez a tábla a RÉSZLETES operatív szerepköröket tárolja.
 */
@Entity
@Table(name = "worker_role_def")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class WorkerRoleDefinition {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    @Column(nullable = false, unique = true, length = 20)
    private String code;

    @Column(name = "name_hu", nullable = false, length = 100)
    private String nameHu;

    @Column(name = "description_hu", length = 500)
    private String descriptionHu;
}
