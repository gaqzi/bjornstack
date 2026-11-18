from decimal import Decimal

from django.test import RequestFactory, TestCase

from shop.admin import OrderAdmin, export_orders_csv
from shop.models import Customer, Order


class ExportOrdersCsvTests(TestCase):
    def test_writes_header_and_one_row(self):
        customer = Customer.objects.create(email="anna@example.se")
        Order.objects.create(customer=customer, status="paid", total=Decimal("249.00"))

        response = export_orders_csv(
            OrderAdmin(Order, None), RequestFactory().get("/"), Order.objects.all()
        )

        lines = response.content.decode().splitlines()
        self.assertEqual(lines[0], "id,customer,status,total,created_at")
        self.assertEqual(len(lines), 2)
        self.assertIn("anna@example.se,paid,249.00", lines[1])
