//
//  Untitled.swift
//  AnchoredPopupExample
//
//  Created by Alisa Mylnikova on 22.01.2025.
//

import SwiftUI
import AnchoredPopup

struct MainView: View {

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                content
            }

            HStack {
                Circle().foregroundStyle(.popupViolet)
                    .overlay {
                        Image(.mainPlay)
                    }
                    .size(60)
                    .useAsPopupAnchor(id: "main_menu") {
                        MainMenuView()
                    } customize: {
                        $0.position(.anchorRelative(.bottomLeading))
                            .background(.none)
                            .isBackgroundPassthrough(true)
                            .closeOnTap(false)
                            .closeOnTapOutside(true)
                    }
                
                Spacer()
                
                Circle().foregroundStyle(RadialGradient(colors: [.popupYellow, .popupYellow2], center: .center, startRadius: 0, endRadius: 30))
                    .overlay {
                        Image(.mainTrophy)
                    }
                    .size(60)
                    .useAsPopupAnchor(id: "congratulations_view") {
                        CongratulationsView()
                    } customize: {
                        $0.position(.screenRelative())
                            .closeOnTap(false)
                            .closeOnTapOutside(true)
                    }
            }
            .padding(16)
        }
    }

    var content: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Today").plexMedium(16, .popupViolet)
                    Text("Sat, 23 April 🌟").chakraMedium(24)
                }

                Spacer()

                Image(.avatar)
                    .useAsPopupAnchor(id: "profile_view") {
                        ProfileView()
                    } customize: {
                        $0.closeOnTap(false)
                            .displayMode(.sheet)
                    }
                    .overlay(alignment: .topTrailing) {
                        Circle().styled(.popupViolet, border: .white, 4)
                            .size(16)
                            .padding(.top, -2)
                            .padding(.trailing, -2)
                    }
            }

            HStack {
                statView(emoji: "🔥", value: "14 920", title: "calories")
                statView(emoji: "💪", value: "8’03”", title: "average pace")
                statView(emoji: "⏱️", value: "1:52:58", title: "time")
            }
            .padding(.vertical, 16)
            .background {
                RoundedRectangle(cornerRadius: 16)
                    .foregroundStyle(.popupLavender)
            }
            .padding(.bottom, 24)

            HStack {
                Text("Select Workout").chakraMedium(24)
                Spacer()
                Text("SEE ALL").plexBold(15, .popupViolet)
            }

            ScrollView(.horizontal) {
                HStack {
                    ForEach(Constants.sportEmoji) { emoji in
                        Circle().foregroundStyle(.popupGray1)
                            .size(80)
                            .overlay {
                                Text(emoji).font(.system(size: 32))
                            }
                    }
                }
            }

            girl1View()
            girl2View()
        }
        .padding(20)
    }

    func statView(emoji: String, value: String, title: String) -> some View {
        VStack {
            Circle().foregroundStyle(.white)
                .size(44).overlay {
                    Text(emoji).font(.system(size: 26))
                }
            Text(value).chakraMedium(20)
            Text(title).plexMedium(12, .popupDarkViolet)
        }
        .greedyWidth()
    }

    func girl1View() -> some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Yoga").chakraMedium(24)
                    .padding(.bottom, 4)
                Text("18 exercises").plex(13, .popupGray2)
                    .padding(.bottom, 16)
                HStack {
                    Image(.mainPlaySmall)
                    Text("60 min").plexMedium(12)
                }
                .padding(16, 6)
                .background {
                    RoundedRectangle(cornerRadius: 6)
                        .foregroundStyle(.popupCornflowerBlue)
                }
            }

            Spacer()
            Image(.girl1)
        }
        .padding(.horizontal, 32)
        .background {
            RoundedRectangle(cornerRadius: 20)
                .foregroundStyle(.popupLightBlue)
                .greedyWidth()
        }
    }

    func girl2View() -> some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Fitness").chakraMedium(24)
                    .padding(.bottom, 4)
                Text("24 exercises").plex(13, .popupGray2)
                    .padding(.bottom, 16)
                HStack {
                    Image(.mainPlaySmall)
                    Text("82 min").plexMedium(12)
                }
                .padding(16, 6)
                .background {
                    RoundedRectangle(cornerRadius: 6)
                        .foregroundStyle(.popupMenthol)
                }
            }

            Spacer()
            Image(.girl2)
        }
        .padding(.horizontal, 32)
        .background {
            RoundedRectangle(cornerRadius: 20)
                .foregroundStyle(.popupLightGreen)
                .greedyWidth()
        }
    }
}
