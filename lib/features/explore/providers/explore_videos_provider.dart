import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/explore_media_type.dart';
import '../models/explore_video.dart';

const _mockMovies = [
  ExploreVideo(id: 'm1', youtubeId: 'O-1WH10hpxI', title: 'Onslaught'),
  ExploreVideo(id: 'm2', youtubeId: '2czXNeNkJY4', title: 'Resident Evil'),
  ExploreVideo(id: 'm3', youtubeId: 'v09vu9E2Cag', title: 'Hexed'),
  ExploreVideo(id: 'm4', youtubeId: '5zHHL67KsDw', title: 'Lucky Strike'),
  ExploreVideo(
    id: 'm5',
    youtubeId: 'bzM-Hdbi2sk',
    title: 'Master of the Universe',
  ),
  ExploreVideo(id: 'm6', youtubeId: 'Xt4X4FvXk2A', title: 'Street Fighter'),
  ExploreVideo(id: 'm7', youtubeId: '0fZ58S-7QP0', title: 'Scary Movie'),
  ExploreVideo(id: 'm8', youtubeId: 'JFQcDFhNh4o', title: 'Heart of the Beast'),
  ExploreVideo(id: 'm9', youtubeId: 'd6HlaHKpl20', title: 'Citizen Vigilante'),
  ExploreVideo(id: 'm10', youtubeId: 'tajfqJsyFvQ', title: 'Hot Spot'),
  ExploreVideo(id: 'm11', youtubeId: 'KCOfvho9A_s', title: 'Kill Code'),
  ExploreVideo(
    id: 'm12',
    youtubeId: 'Zggye4QF7AE',
    title: 'Blades of the Guardians',
  ),
  ExploreVideo(
    id: 'm13',
    youtubeId: 'yyW8FVZAFB4',
    title: 'The End of Oak Street',
  ),
  ExploreVideo(id: 'm14', youtubeId: 'FCTEBnJDhFA', title: 'Mind Games'),
  ExploreVideo(id: 'm15', youtubeId: 'eHXldvEs3JU', title: 'Pressure'),
  ExploreVideo(id: 'm16', youtubeId: 'eDvO0xMWwxI', title: 'The Passenger'),
  ExploreVideo(id: 'm17', youtubeId: 'kWRAPN13cco', title: 'Whalefall'),
  ExploreVideo(id: 'm18', youtubeId: 'TBGE-vnvQq0', title: 'Tuner'),
  ExploreVideo(id: 'm19', youtubeId: '_9N1bC683m4', title: 'No Ordinary Heist'),
  ExploreVideo(
    id: 'm20',
    youtubeId: 'Vlp8sV9cyAU',
    title: 'This Tempting Madness',
  ),
];

const _mockSeries = [
  ExploreVideo(id: 's1', youtubeId: 'LTss4risHbE', title: 'From — Season 4'),
  ExploreVideo(
    id: 's2',
    youtubeId: 'YUycK-9m1vQ',
    title: 'Avatar: The Last Airbender — Season 2',
  ),
  ExploreVideo(id: 's3', youtubeId: 'Trp4FbB-Gfw', title: 'The Boroughs'),
  ExploreVideo(
    id: 's4',
    youtubeId: 'VWL1zH2q2Zk',
    title: 'Salish & Jordan Matter',
  ),
  ExploreVideo(id: 's5', youtubeId: 'LM1x8D3uUpI', title: 'Thrash'),
  ExploreVideo(id: 's6', youtubeId: 'ovqCBHdm4NE', title: 'The East Palace'),
  ExploreVideo(id: 's7', youtubeId: 'MJo_J9bHM7I', title: 'The Last House'),
  ExploreVideo(id: 's8', youtubeId: 'fUXGrunDo_4', title: 'Nemesis'),
  ExploreVideo(
    id: 's9',
    youtubeId: 'Z8pes4PRAUQ',
    title: 'Norway: The Dark Horse',
  ),
  ExploreVideo(id: 's10', youtubeId: 'zK4dMBXfdpg', title: 'The Westies'),
  ExploreVideo(
    id: 's11',
    youtubeId: 'ZozrvCiB06Q',
    title: 'Your Friends & Neighbors — Season 2',
  ),
  ExploreVideo(
    id: 's12',
    youtubeId: 'lBmKNJ9i3N4',
    title: 'This Is Not a Murder Mystery',
  ),
  ExploreVideo(
    id: 's13',
    youtubeId: '7Wc6ugY3meg',
    title: 'Crunchyroll — Spring 2026 Season',
  ),
  ExploreVideo(id: 's14', youtubeId: 'zXQ4tyg2cm0', title: 'Killtube'),
  ExploreVideo(id: 's15', youtubeId: 'yBJAEWoEUZ0', title: 'Star City'),
  ExploreVideo(
    id: 's16',
    youtubeId: 'SXiSfXiiOxM',
    title: 'Kaiju No. 8 — Season 2',
  ),
];

final exploreVideosProvider =
    Provider.family<List<ExploreVideo>, ExploreMediaType>((ref, type) {
      return switch (type) {
        ExploreMediaType.movies => _mockMovies,
        ExploreMediaType.series => _mockSeries,
      };
    });
