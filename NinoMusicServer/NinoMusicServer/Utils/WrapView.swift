//
//  WrapView.swift
//  TelaConfig
//
//  Created by Luiz Guilherme Baptista Machado on 20/03/26.
//

import SwiftUI

struct WrapView<Data: Collection, Content: View>: View where Data.Element: Hashable {
    
    let items: Data
    let content: (Data.Element) -> Content
    
    var body: some View {
        FlowLayout(items: items, content: content)
    }
}
