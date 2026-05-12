//
//  FlowLayout.swift
//  ListingLens
//
//  Created by Fardin Zaman on 5/11/26.
//

import SwiftUI

struct FlowLayout: Layout {
    var spacing: CGFloat

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Void
    ) -> CGSize {
        let width = proposal.width ?? 320
        let rows = rows(for: subviews, maxWidth: width)
        return CGSize(width: width, height: rows.last?.maxY ?? 0)
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Void
    ) {
        let rows = rows(for: subviews, maxWidth: bounds.width)
        for row in rows {
            for item in row.items {
                subviews[item.index].place(
                    at: CGPoint(x: bounds.minX + item.origin.x, y: bounds.minY + item.origin.y),
                    proposal: ProposedViewSize(item.size)
                )
            }
        }
    }

    private func rows(for subviews: Subviews, maxWidth: CGFloat) -> [FlowRow] {
        var rows: [FlowRow] = []
        var currentItems: [FlowItem] = []
        var origin = CGPoint.zero
        var rowHeight: CGFloat = 0

        for index in subviews.indices {
            let size = subviews[index].sizeThatFits(.unspecified)
            if origin.x + size.width > maxWidth, !currentItems.isEmpty {
                rows.append(FlowRow(items: currentItems, maxY: origin.y + rowHeight))
                origin.x = 0
                origin.y += rowHeight + spacing
                rowHeight = 0
                currentItems = []
            }

            currentItems.append(FlowItem(index: index, origin: origin, size: size))
            origin.x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }

        if !currentItems.isEmpty {
            rows.append(FlowRow(items: currentItems, maxY: origin.y + rowHeight))
        }

        return rows
    }

    private struct FlowItem {
        let index: Int
        let origin: CGPoint
        let size: CGSize
    }

    private struct FlowRow {
        let items: [FlowItem]
        let maxY: CGFloat
    }
}
