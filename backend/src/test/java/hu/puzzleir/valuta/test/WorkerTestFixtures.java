package hu.puzzleir.valuta.test;

import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.entity.Worker;
import hu.puzzleir.valuta.entity.WorkerRole;

import java.util.UUID;

public final class WorkerTestFixtures {

    private static final UUID COMPANY_ID = UUID.fromString("10000000-0000-0000-0000-000000000001");
    private static final UUID BRANCH_ID = UUID.fromString("20000000-0000-0000-0000-000000000001");

    private WorkerTestFixtures() {
    }

    public static Worker worker() {
        Company company = Company.builder()
                .id(COMPANY_ID)
                .code("EBC")
                .name("Exchange Best Change")
                .build();
        Branch branch = Branch.builder()
                .id(BRANCH_ID)
                .company(company)
                .code("KORUT")
                .name("Korut")
                .city("Szeged")
                .address("Teszt utca 1")
                .build();
        Worker worker = new Worker();
        worker.setId(42L);
        worker.setCompany(company);
        worker.setBranch(branch);
        worker.setCode("BORSI");
        worker.setName("Borsi Tamas");
        worker.setRole(WorkerRole.CASHIER);
        worker.setActive(true);
        return worker;
    }
}
