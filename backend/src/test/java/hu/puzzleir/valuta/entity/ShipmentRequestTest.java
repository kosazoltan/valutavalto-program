package hu.puzzleir.valuta.entity;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatCode;

class ShipmentRequestTest {

    @Test
    @DisplayName("wireItemBackReferences: minden tétel szülő-referenciáját beállítja")
    void wireItemBackReferencesSetsParentOnAllItems() {
        ShipmentRequest request = ShipmentRequest.builder().build();
        ShipmentRequestItem firstItem = item(1L, "1000.00");
        ShipmentRequestItem secondItem = item(2L, "2000.00");
        request.getItems().addAll(List.of(firstItem, secondItem));

        assertThat(request.getItems())
                .allSatisfy(shipmentItem -> assertThat(shipmentItem.getShipmentRequest()).isNull());

        request.wireItemBackReferences();

        assertThat(request.getItems())
                .allSatisfy(shipmentItem -> assertThat(shipmentItem.getShipmentRequest()).isSameAs(request));
    }

    @Test
    @DisplayName("wireItemBackReferences: idempotens és tolerálja a null/üres tétellistát")
    void wireItemBackReferencesIsIdempotentAndNullSafe() {
        ShipmentRequest request = ShipmentRequest.builder().build();
        ShipmentRequestItem alreadyWiredItem = item(1L, "1000.00");
        request.addItem(alreadyWiredItem);
        request.getItems().add(null);

        assertThatCode(request::wireItemBackReferences).doesNotThrowAnyException();
        assertThat(alreadyWiredItem.getShipmentRequest()).isSameAs(request);

        request.setItems(null);

        assertThat(request.getItems()).isEmpty();
        assertThatCode(request::wireItemBackReferences).doesNotThrowAnyException();
    }

    private static ShipmentRequestItem item(Long currencyId, String requestedAmount) {
        return ShipmentRequestItem.builder()
                .currencyId(currencyId)
                .requestedAmount(new BigDecimal(requestedAmount))
                .build();
    }
}
