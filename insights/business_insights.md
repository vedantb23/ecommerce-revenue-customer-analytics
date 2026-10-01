# Business Insights Summary

## E-Commerce Revenue, Customer & Operations Analytics
**Analysis by Vedant Bhavsar**

---

## 1. Revenue Performance

- **Total revenue: R$ 13.59M** across ~96K delivered orders (Sep 2016 – Oct 2018).
- Revenue showed **strong growth from 2017 through mid-2018**, stabilizing in late 2018.
- **Average Order Value (AOV): ~R$ 138**, with significant variance (high-value outliers exist).
- São Paulo state alone accounts for a disproportionate share of revenue.

---

## 2. Customer Behavior

- **96,096 unique customers** identified (using `customer_unique_id`).
- **Only 3.12% are repeat buyers** (2,997 out of 96,096).
- The vast majority (96.88%) made exactly **one purchase** and never returned.
- Repeat customers have a **higher average spend per customer** than one-time buyers.

---

## 3. Product & Category Performance

- **Top 3 categories by revenue:** health_beauty, watches_gifts, bed_bath_table.
- Revenue follows a **Pareto pattern** — a small number of categories drive the majority of sales.
- Categories vary significantly in average review scores, suggesting quality differences.

---

## 4. Delivery & Operations

- Average delivery time: approximately **12 days** from purchase to delivery.
- **Late deliveries have measurably lower review scores** compared to on-time deliveries.
- Late delivery percentage varies by state — logistics performance is **geographically uneven**.

---

## 5. RFM Segmentation

- Most customers fall into **'New Customers'** and **'Lost / Low Value'** segments (expected given the 3% repeat rate).
- **'Champions'** (high R, F, M scores) represent a very small but high-value group.
- A significant number of customers are classified as **'Needs Attention'** or **'Potential Loyalists'**.

---

## 6. Cohort Retention

- Retention **drops sharply after Month 0** — very few customers return for a second purchase.
- Early cohorts (2017) show marginally better retention than later cohorts.
- The low repeat rate suggests the platform functions more as a **one-time purchase marketplace**.

---

## Recommendations

| # | Finding | Implication | Recommendation |
|---|---------|-------------|----------------|
| 1 | 96.9% of customers are one-time buyers | Revenue depends on constantly acquiring new customers | Launch re-engagement campaigns within 30 days of first purchase |
| 2 | Top categories drive majority of revenue | Over-reliance on few categories creates risk | Diversify marketing across high-potential categories |
| 3 | Late deliveries reduce review scores | Poor logistics hurts customer satisfaction and retention | Focus logistics improvement on worst-performing states |
| 4 | Large 'Lost / Low Value' RFM segment | These customers are unlikely to return without intervention | Design targeted win-back campaigns with discounts |
| 5 | Retention drops sharply after first month | No effective post-purchase engagement exists | Implement loyalty program or second-purchase incentive |

---

*Note: All numbers are derived from actual analysis of the Olist dataset. No estimates or fabricated impact metrics are included.*
