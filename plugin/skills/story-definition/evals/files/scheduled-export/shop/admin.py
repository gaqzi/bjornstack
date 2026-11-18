import csv

from django.contrib import admin
from django.http import HttpResponse

from .models import Order


@admin.action(description="Export selected orders to CSV")
def export_orders_csv(modeladmin, request, queryset):
    response = HttpResponse(content_type="text/csv")
    response["Content-Disposition"] = 'attachment; filename="orders.csv"'
    writer = csv.writer(response)
    writer.writerow(["id", "customer", "status", "total", "created_at"])
    for order in queryset.order_by("created_at"):
        writer.writerow([
            order.id,
            order.customer.email,
            order.status,
            order.total,
            order.created_at.isoformat(),
        ])
    return response


@admin.register(Order)
class OrderAdmin(admin.ModelAdmin):
    list_display = ("id", "customer", "status", "total", "created_at")
    list_filter = ("status", "created_at")
    actions = [export_orders_csv]
