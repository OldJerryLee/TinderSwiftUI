//
//  ContentView.swift
//  Tinder
//
//  Created by Fabricio Pujol on 06/04/20.
//  Copyright © 2020 Fabricio Pujol. All rights reserved.
//

import SwiftUI
import Firebase
import SDWebImage

struct ContentView: View {

    @EnvironmentObject var obs: observer

    var body: some View {

        ZStack {
            Color("LightWhite").edgesIgnoringSafeArea(.all)

            if obs.users.isEmpty {
                Loader()
            }
            VStack {
                TopView()

                SwipeView()

                BottomView()
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

struct SwipeDetailsView: View {
    var name = ""
    var age = ""
    var image = ""
    var height : CGFloat = 0

    var body: some View {
        ZStack {
            Image("dog").resizable().cornerRadius(20).padding(.horizontal, 15)

            VStack {
                Spacer()

                HStack {

                    VStack(alignment:.leading ,content: {
                        Text(name).font(.system(size: 25)).fontWeight(.heavy).foregroundColor(.white)
                        Text(age).foregroundColor(.white)
                    })

                    Spacer()
                }

            }.padding([.bottom,.leading], 35)
        }.frame(height: height)
    }
}

struct TopView: View {
    var body: some View {
        HStack {
            Button(action: {
            }) {
                Image(systemName: "person.fill").resizable().frame(width: 35, height: 35)
            }.foregroundColor(.gray)

            Spacer()

            Button(action: {
            }) {
                Image(systemName: "flame.fill").resizable().frame(width: 30, height: 35)
            }.foregroundColor(.red)

            Spacer()

            Button(action: {
            }) {
                Image(systemName: "message.fill").resizable().frame(width: 35, height: 35)
            }.foregroundColor(.gray)
        }.padding()
    }
}

struct BottomView: View {

    @EnvironmentObject var obs: observer

    var body: some View {
        HStack {
            Button(action: {
                if self.obs.last != -1 {
                    self.obs.goBack(index: self.obs.last)
                }
            }){
                Image(systemName: "goforward").resizable().frame(width: 25, height: 25).padding()
                }.foregroundColor(.yellow).background(Color.white).shadow(radius: 25).clipShape(Circle())

            Button(action: {

            }){
                Image(systemName: "xmark").resizable().frame(width: 35, height: 35).padding()
                }.foregroundColor(.red).background(Color.white).shadow(radius: 25).clipShape(Circle())

            Button(action: {

            }){
                Image(systemName: "star.fill").resizable().frame(width: 25, height: 25).padding()
                }.foregroundColor(.blue).background(Color.white).shadow(radius: 25).clipShape(Circle())

            Button(action: {

            }){
                Image(systemName: "heart.fill").resizable().frame(width: 35, height: 35).padding()
                }.foregroundColor(.green).background(Color.white).shadow(radius: 25).clipShape(Circle())

            Button(action: {

            }){
                Image(systemName: "bolt.fill").resizable().frame(width: 25, height: 25).padding()
                }.foregroundColor(.purple).background(Color.white).shadow(radius: 25).clipShape(Circle())
        }
    }
}

struct SwipeView: View {

    @EnvironmentObject var obser : observer
    let imageView = SDAnimatedImageView()

    var body: some View {
        GeometryReader{ geo in
            ZStack{
                ForEach(self.obser.users){i in
                    SwipeDetailsView(name: i.name, age: i.age, image: "", height: geo.size.height - 100).gesture(DragGesture()
                        .onChanged({ (value) in
                            if value.translation.width > 0 {
                                self.obser.update(id: i, value: value.translation.width, degree: 8)
                            } else {
                                self.obser.update(id: i, value: value.translation.width, degree: -8)
                            }
                        }).onEnded({ (value) in

                            if i.swipe > 0 {
                                if  i.swipe > geo.size.width / 2 - 80 {
                                    self.obser.update(id: i, value: 500, degree: 0)
                                    self.obser.updateDB(id: i, status: "liked")
                                } else {
                                    self.obser.update(id: i, value: 0, degree: 0)
                                }
                            } else {
                                if  -i.swipe > geo.size.width / 2 - 80 {
                                    self.obser.update(id: i, value: -500, degree: 0)
                                    self.obser.updateDB(id: i, status: "reject")
                                } else {
                                    self.obser.update(id: i, value: 0, degree: 0)
                                }
                            }

                        })
                    ).offset(x: i.swipe).rotationEffect(.init(degrees: i.degree)).animation(.spring())
                }
            }
        }
    }
}

struct Loader: UIViewRepresentable {
    func makeUIView(context: UIViewRepresentableContext<Loader>) -> UIActivityIndicatorView {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.startAnimating()
        return indicator
    }

    func updateUIView(_ uiView: UIActivityIndicatorView, context: UIViewRepresentableContext<Loader>) {

    }
}

class observer: ObservableObject {
    @Published var users = [dataType]()
    @Published var last = -1

    init() {
        let db = Firestore.firestore()

        db.collection("users").getDocuments { (snap, err) in
            if err != nil {
                print((err?.localizedDescription)!)
                return
            }

            for i in snap!.documents {
                let name = i.get("name") as! String
                let age = i.get("age") as! String
                let image = i.get("image") as! String
                let id = i.documentID
                let status = i.get("status") as! String

                if status == "" {
                    self.users.append(dataType(id: id, name: name, image: image, age: age, swipe: 0, degree: 0))
                }
            }
        }
    }

    func update(id: dataType, value: CGFloat, degree: Double){
        for i in 0..<self.users.count {
            if self.users[i].id == id.id {
                self.users[i].swipe = value
                self.users[i].degree = degree
                self.last = i
            }
        }
    }

    func goBack(index: Int){
        self.users[index].swipe = 0
    }

    func updateDB(id: dataType, status: String){
        let db = Firestore.firestore()

        db.collection("users").document(id.id).updateData(["status":status]) { (err) in
            if err != nil {
                print(err)
                return
            }

            print("success")

            for i in 0..<self.users.count {
                if self.users[i].id == id.id{
                    if status == "liked" {
                        self.users[i].swipe = 500
                    } else {
                        self.users[i].swipe = -500
                    }
                }
            }

        }
    }
}

struct dataType : Identifiable {
    var id: String
    var name: String
    var image: String
    var age: String
    var swipe: CGFloat
    var degree: Double
}
