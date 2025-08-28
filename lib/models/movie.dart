class Movie {
  final String id;
  final String title;
  final int? year;
  final String? genre;
  final String? rating;
  final String? director;
  final List<String> images; // Image listesi
  final String poster;
  final int view;
  final int right;

  Movie({
    required this.id,
    required this.title,
    required this.images,
    required this.poster,
    this.year,
    this.genre,
    this.rating,
    this.director,
    this.view = 0,
    this.right = 0,
  });

  factory Movie.fromMap(Map<dynamic, dynamic> map) {
    final imgs = <String>[];
    for (int i = 1; i <= 5; i++) {
      final imageKey = 'Image$i';
      final imageUrl = map[imageKey];
      if (imageUrl is String && imageUrl.isNotEmpty) {
        imgs.add(imageUrl);
      }
    }
    print('Parsing movie: $map'); // Debug
    return Movie(
      id: map['Id'] as String? ?? 'unknown', // Null kontrolü
      title: map['Title'] as String? ?? 'Unknown', // Null kontrolü
      year: (map['Year'] is int) ? map['Year'] as int : int.tryParse('${map['Year']}') ?? 0,
      genre: map['Genre'] as String?,
      rating: map['Rating'] as String?,
      director: map['Director'] as String?,
      images: imgs,
      poster: map['Poster'] as String? ?? '',
      view: (map['View'] ?? 0) as int,
      right: (map['Right'] ?? 0) as int,
    );
  }

  Map<String, dynamic> toMap() => {
    'Id': id,
    'Title': title,
    'Year': year,
    'Genre': genre,
    'Rating': rating,
    'Director': director,
    'Images': images,
    'Poster': poster,
    'View': view,
    'Right': right,
  };
}