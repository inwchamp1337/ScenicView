//
//  ViewController.swift
//  onther1
//
//  Created by lightyear on 3/2/2568 BE.
//

import UIKit
import SDWebImage

// MARK: - Custom Table View Cell
class CustomTableViewCell: UITableViewCell {
    static let identifier = "CustomCell"
    
    private let photoImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 8
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = .darkGray
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let positiveVoteCountLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 10)
        label.textColor = .gray
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let likeImageView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(named: "like")
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.addSubview(photoImageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(descriptionLabel)
        contentView.addSubview(positiveVoteCountLabel)
        contentView.addSubview(likeImageView)
        
        NSLayoutConstraint.activate([
            photoImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            photoImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            photoImageView.widthAnchor.constraint(equalToConstant: 80),
            photoImageView.heightAnchor.constraint(equalToConstant: 80),
            
            likeImageView.trailingAnchor.constraint(equalTo: positiveVoteCountLabel.leadingAnchor, constant: -4),
            likeImageView.centerYAnchor.constraint(equalTo: positiveVoteCountLabel.centerYAnchor),
            
            positiveVoteCountLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            positiveVoteCountLabel.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            
            titleLabel.leadingAnchor.constraint(equalTo: photoImageView.trailingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: positiveVoteCountLabel.leadingAnchor, constant: -8),
            titleLabel.topAnchor.constraint(equalTo: photoImageView.topAnchor),
            
            descriptionLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            descriptionLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            descriptionLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -8)
        ])
    }
    
    func configure(with photo: Photo) {
        titleLabel.text = photo.name
        descriptionLabel.text = photo.description
        positiveVoteCountLabel.text = "\(photo.positive_votes_count)"
        
        if let imageUrl = photo.image_url.first {
            photoImageView.sd_setImage(
                with: URL(string: imageUrl),
                placeholderImage: UIImage(named: "placeholder")
            )
        }
    }
}

// MARK: - View Controller
class ViewController: UIViewController {
    private let tableView: UITableView = {
        let tv = UITableView()
        tv.separatorStyle = .none
        tv.translatesAutoresizingMaskIntoConstraints = false
        return tv
    }()
    
    private var photos: [Photo] = [] {
        didSet {
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        fetchPhotos()
    }
    
    private func setupTableView() {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(handleRefresh(_:)), for: .valueChanged)
        tableView.refreshControl = refreshControl
        
        view.addSubview(tableView)
        tableView.register(CustomTableViewCell.self, forCellReuseIdentifier: CustomTableViewCell.identifier)
        tableView.dataSource = self
        tableView.delegate = self
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func fetchPhotos() {
        let urlString = "https://api.500px.com/v1/photos?feature=popular&page=1"
        
        guard let url = URL(string: urlString) else {
            print("Invalid URL")
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
                return
            }
            
            guard let data = data else {
                print("No data received")
                return
            }
            
            do {
                let decoder = JSONDecoder()
                let response = try decoder.decode(PhotoResponse.self, from: data)
                self?.photos = Array(response.photos.prefix(1000))
            } catch {
                print("Decoding error: \(error)")
            }
        }
        task.resume()
    }
    
    @objc private func handleRefresh(_ refreshControl: UIRefreshControl) {
        photos.shuffle()
        refreshControl.endRefreshing()
    }
}

// MARK: - TableView DataSource & Delegate
extension ViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return photos.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: CustomTableViewCell.identifier, for: indexPath) as! CustomTableViewCell
        cell.configure(with: photos[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
}

