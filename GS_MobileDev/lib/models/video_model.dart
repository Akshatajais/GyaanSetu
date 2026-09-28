class VideoModel {
  final String title;
  final String url;
  final String duration;
  final String? thumbnailUrl;

  VideoModel({
    required this.title,
    required this.url,
    required this.duration,
    this.thumbnailUrl,
  });

  factory VideoModel.fromJson(Map<String, dynamic> json) {
    return VideoModel(
      title: json['title'] ?? '',
      url: json['url'] ?? '',
      duration: json['duration'] ?? '',
      thumbnailUrl: json['thumbnailUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'url': url,
      'duration': duration,
      'thumbnailUrl': thumbnailUrl,
    };
  }
}