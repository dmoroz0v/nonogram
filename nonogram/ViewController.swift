//
//  ViewController.swift
//  nonogram
//
//  Created by Denis S. Morozov on 12.01.2023.
//

import UIKit

extension String {
    public func matching(_ pattern: String, options: NSRegularExpression.Options = []) -> [String] {
        guard let regEx = try? NSRegularExpression(pattern: pattern, options: options) else {
            return []
        }

        return regEx.matches(in: self, range: NSRange(location: 0, length: count)).map { match in
            guard let range = Range(match.range) else {
                return ""
            }
            let startIndex = index(self.startIndex, offsetBy: range.startIndex)
            let endIndex = index(self.startIndex, offsetBy: range.endIndex)
            return String(self[startIndex..<endIndex])
        }
    }
}

class ViewController: UIViewController, ResolvingViewControllerDelegate, MenuViewControllerDelegate {

    var currentViewController: UIViewController?

    func menuViewController(_: MenuViewController, load url: URL) {
        do {
            let data = try Data(contentsOf: url)

            var d: [[Int]] = []

            if var s = String(data: data, encoding: .utf8) {
                s = s.matching("d=\\[\\[.+?\\]\\]").first!
                s = s.replacingOccurrences(of: "d=[[", with: "")
                s = s.replacingOccurrences(of: "]]", with: "")
                let rows = s.split(separator: "],[")

                for row in rows {
                    var arr: [Int] = []
                    for ch in row.split(separator: ",") {
                        arr.append(Int(ch)!)
                    }
                    d.append(arr)
                }
            }

            var E: [[Int]] = []

            let D: Int = d[1][0] % d[1][3] + d[1][1] % d[1][3] - d[1][2] % d[1][3]
            let C: Int = d[2][0] % d[2][3] + d[2][1] % d[2][3] - d[2][2] % d[2][3]
            let Aa: Int = d[3][0] % d[3][3] + d[3][1] % d[3][3] - d[3][2] % d[3][3]
            var colors: [String] = []

            for x in 5..<(Aa + 5) {
                let Ea = d[x][0] - d[4][1]
                let Fa = d[x][1] - d[4][0]
                let Ga = d[x][2] - d[4][3]

                var s1 = String(format:"%02X", Ea + 256)
                s1 = String(s1[(s1.index(s1.startIndex, offsetBy: 1))..<s1.endIndex])

                var s2 = String(format:"%02X", ((Fa + 256) << 8) + Ga)
                s2 = String(s2[(s2.index(s1.startIndex, offsetBy: 1))..<s2.endIndex])

                colors.append(s1 + s2)
            }

            for w in 0..<C {
                E.append([])
                for _ in 0..<D {
                    E[w].append(0)
                }

            }
            let V = Aa + 5
            let Ha = d[V][0] % d[V][3] * (d[V][0] % d[V][3]) + d[V][1] % d[V][3] * 2 + d[V][2] % d[V][3]
            let Ia: [Int] = d[V + 1]

            for x in (V + 2)..<(V + 1 + Ha) {
                let start: Int = (d[x][0] - Ia[0] - 1)
                let end: Int = (d[x][0] - Ia[0] + d[x][1] - Ia[1] - 1)
                for v in start..<end {
                    E[d[x][3] - Ia[3] - 1][v] = d[x][2] - Ia[2]
                }
            }

            var verticals: [[Field.Definition]] = []
            var horizontal: [[Field.Definition]] = []

            for row in E {
                var n = 0
                var color: String = ""
                var horizontalRow: [Field.Definition] = []
                var prevCh: Int = -1
                for ch in row {
                    if prevCh != ch && prevCh != -1 && prevCh != 0 {
                        horizontalRow.append(.init(color: .init(rgb: color), n: n))
                        n = 0
                    }
                    if ch != 0 {
                        n += 1
                        color = colors[ch - 1]
                    }
                    prevCh = ch
                }
                if n != 0 {
                    horizontalRow.append(.init(color: .init(rgb: color), n: n))
                }
                horizontal.append(horizontalRow)
            }

            for i in 0..<E[0].count {
                var n = 0
                var color: String = ""
                var verticalRow: [Field.Definition] = []
                var prevCh: Int = -1
                for j in 0..<E.count {
                    let ch = E[j][i]
                    if prevCh != ch && prevCh != -1 && prevCh != 0 {
                        verticalRow.append(.init(color: .init(rgb: color), n: n))
                        n = 0
                    }
                    if ch != 0 {
                        n += 1
                        color = colors[ch - 1]
                    }
                    prevCh = ch
                }
                if n != 0 {
                    verticalRow.append(.init(color: .init(rgb: color), n: n))
                }
                verticals.append(verticalRow)
            }

            let resolvingViewController = ResolvingViewController(
                horizintals: horizontal,
                verticals: verticals,
                solution: E,
                colors: colors.map({
                    Field.Color(rgb: $0)
                })
            )

            resolvingViewController.delegate = self

            showVC(resolvingViewController)
        }
        catch {
        }
    }

    func menuViewControllerContinue(_: MenuViewController) {
        if let data = storage.load() {
            let resolvingViewController = ResolvingViewController(
                field: data.field,
                layers: data.layers,
                currentLayer: data.currentLayer,
                solution: data.solution,
                colors: data.colors
            )

            resolvingViewController.delegate = self
            showVC(resolvingViewController)
        }
    }

    var storage: Storage = Storage()

    func resolvingViewController(
        _ vc: ResolvingViewController,
        didChangeState field: Field,
        layers: [String : Field],
        currentLayer: String?
    ) {
        storage.save(
            field: field,
            layers: layers,
            currentLayer: currentLayer,
            solution: vc.solution,
            colors: vc.colors
        )
    }

    func resolvingViewControllerDidTapExit(_: ResolvingViewController) {
        let menuVC = MenuViewController()
        menuVC.delegate = self

        showVC(menuVC)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let menuVC = MenuViewController()
        menuVC.delegate = self

        showVC(menuVC)
    }

    func showVC(_ vc: UIViewController) {
        if let currentViewController = currentViewController {
            currentViewController.willMove(toParent: nil)
            currentViewController.view.removeFromSuperview()
            currentViewController.removeFromParent()
        }

        currentViewController = vc

        addChild(vc)
        view.addSubview(vc.view)
        vc.didMove(toParent: self)

        NSLayoutConstraint.activate([
            vc.view.topAnchor.constraint(equalTo: view.topAnchor),
            vc.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            vc.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            vc.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
    }

}
