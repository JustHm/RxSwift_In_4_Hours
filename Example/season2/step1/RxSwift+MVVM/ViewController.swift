//
//  ViewController.swift
//  RxSwift+MVVM
//
//  Created by iamchiwon on 05/08/2019.
//  Copyright © 2019 iamchiwon. All rights reserved.
//

import RxSwift
import SwiftyJSON
import UIKit

let MEMBER_LIST_URL = "https://my.api.mockaroo.com/members_with_avatar.json?key=44ce18f0"

class 나중에생기는데이터<T> { //RX로 치면 Observable
    // 실행할 태스크를 가지고 있다가 나중에오면 함수가 호출되면 completion과 같은 동작을 해줌.?
    // RX와 같은 동작을 함.
    private let task: (@escaping (T) -> Void) -> Void
    init(task: @escaping (@escaping (T) -> Void) -> Void) {
        self.task = task
    }
    func 나중에오면(_ f: @escaping (T)->Void) {
        task(f)
    }
}

class ViewController: UIViewController {
    @IBOutlet var timerLabel: UILabel!
    @IBOutlet var editView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.timerLabel.text = "\(Date().timeIntervalSince1970)"
        }
    }
    
    private func setVisibleWithAnimation(_ v: UIView?, _ s: Bool) {
        guard let v = v else { return }
        UIView.animate(withDuration: 0.3, animations: { [weak v] in
            v?.isHidden = !s
        }, completion: { [weak self] _ in
            self?.view.layoutIfNeeded()
        })
    }
    
    func downloadJson(_ url: String) -> Observable<String?> {
        // Observable 생명주기 : create -> subscribe -> next/error -> complete
        return Observable<String?>.create() { observer in
            let url = URL(string: url)!
            let task = URLSession.shared.dataTask(with: url) { data, _, error in
                guard error == nil else {
                    observer.onError(error!)
                    return
                }
                if let data,
                   let json = String(data: data, encoding: .utf8) {
                    observer.onNext(json)
                }
                observer.onCompleted()
            }
            task.resume()
            return Disposables.create { task.cancel()} //dispose가 호출되면 이 블럭이 실행된다.
        }
        
        //        // 1. 비동기로 생기는 데이터를 Observable로 감싸서 return하는 방법
        //        return Observable<String?>.create { observer -> Disposable in
        //            DispatchQueue.global().async {
        //                let url = URL(string: url)!
        //                let data = try! Data(contentsOf: url)
        //                let json = String(data: data, encoding: .utf8)
        //                DispatchQueue.main.async {
        //                    observer.onNext(json)
        //                    observer.onCompleted()
        //                }
        //            }
        //            return Disposables.create{} //
        //        }
    }
    
    // MARK: SYNC
    
    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    
    @IBAction func onLoad() {
        editView.text = ""
        self.setVisibleWithAnimation(self.activityIndicator, true)
        /*
         [weak self]로 순환참조를 방지해줘야 하지만, 안해도 되는 이유는?
         일단 순환참조가 생기는 이유는 클로저가 self를 캡처해서 ARC count가 증가한 상태여서, 클로저가 없어지기만 하면 순환참조 발생 하지 않음.
         complete or error 호출이 되면 클로저가 동작을 다 했다고 알리는 것이여서 클로저가 사라짐.
         */
        let observable = downloadJson(MEMBER_LIST_URL)
        observable
            .debug() // 동작을 출력해줌.
            .observeOn(MainScheduler.instance) //옵저버가 어느 스케줄러 상에서 Observable을 관찰할지 명시한다. (operator)
            .subscribe(onNext: { json in
                //DispatchQueue.main.async { //URLSession을 썼을 땐 URLSession의 태스크에서 evnet가 들어왔기 때문에 UI Update는 main에서
                self.editView.text = json
                self.setVisibleWithAnimation(self.activityIndicator, false)
                //}
            })
        // Observable이 error or compelte 되면 자동으로 dispose된다.
        
    }
}
