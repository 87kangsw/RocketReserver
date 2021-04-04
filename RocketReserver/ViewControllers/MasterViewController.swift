//
//  MasterViewController.swift
//  RocketReserver
//
//  Created by Kanz on 2021/04/04.
//

import UIKit

import Apollo
import SDWebImage

enum ListSection: Int, CaseIterable {
    case launches
    case loading
}

class MasterViewController: UIViewController {
    
    // MARK: Views
    @IBOutlet weak var tableView: UITableView!
    
    // MARK: Property
    var launches = [LaunchListQuery.Data.Launch.Launch]()
    private var lastConnection: LaunchListQuery.Data.Launch?
    private var activeRequest: Cancellable?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.dataSource = self
        tableView.delegate = self
        
        self.loadMoreLaunchesIfTheyExist()
    }
    
    
    // MARK: Private
    private func showErrorAlert(title: String, message: String) {
        let alert = UIAlertController(title: title,
                                      message: message,
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        self.present(alert, animated: true)
    }
    
    private func loadMoreLaunches(from cursor: String?) {
        self.activeRequest = Network.shared.apollo.fetch(query: LaunchListQuery(cursor: cursor)) { [weak self] result in
            guard let self = self else { return }
            
            self.activeRequest = nil
            defer {
                self.tableView.reloadData()
            }
            
            switch result {
            case .success(let graphQLResult):
                if let launchConnection = graphQLResult.data?.launches {
                    self.lastConnection = launchConnection
                    self.launches.append(contentsOf: launchConnection.launches.compactMap { $0 })
                }
                
                if let errors = graphQLResult.errors {
                    let message = errors
                        .map { $0.localizedDescription }
                        .joined(separator: "\n")
                    self.showErrorAlert(title: "GraphQL Error(s)",
                                        message: message)
                }
            case .failure(let error):
                self.showErrorAlert(title: "Network Error",
                                    message: error.localizedDescription)
            }
        }
    }
    
    private func loadMoreLaunchesIfTheyExist() {
        guard let connection = self.lastConnection else {
            // We don't have stored launch details, load from scratch
            self.loadMoreLaunches(from: nil)
            return
        }
        
        guard connection.hasMore else {
            // No more launches to fetch
            return
        }
        
        self.loadMoreLaunches(from: connection.cursor)
    }
    
    // MARK: - Route
    private func pushToDetail(launchID: GraphQLID) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let viewController = storyboard.instantiateViewController(withIdentifier: "DetailViewController") as? DetailViewController else { return }
        viewController.launchID = launchID
        self.navigationController?.pushViewController(viewController, animated: true)
    }
}

// MARK: - UITableViewDataSource, UITableViewDelegate
extension MasterViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return ListSection.allCases.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let listSection = ListSection(rawValue: section) else {
            assertionFailure("Invalid Section")
            return 0
        }
        
        switch listSection {
        case .launches:
            return self.launches.count
        case .loading:
            if self.lastConnection?.hasMore == false {
                return 0
            } else {
                return 1
            }
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.imageView?.image = nil
        cell.textLabel?.text = nil
        cell.detailTextLabel?.text = nil
        
        guard let listSection = ListSection(rawValue: indexPath.section) else {
            assertionFailure("Invalid section")
            return cell
        }
        
        switch listSection {
        case .launches:
            let launch = self.launches[indexPath.row]
            cell.textLabel?.text = launch.mission?.name
            cell.detailTextLabel?.text = launch.site
            
            let placeholder = UIImage(named: "placeholder")!
            
            if let missionPatch = launch.mission?.missionPatch {
                cell.imageView?.sd_setImage(with: URL(string: missionPatch)!, placeholderImage: placeholder)
            } else {
                cell.imageView?.image = placeholder
            }
            
        case .loading:
            if self.activeRequest == nil {
                cell.textLabel?.text = "Tap to load more"
            } else {
                cell.textLabel?.text = "Loading..."
            }
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        guard let listSection = ListSection(rawValue: indexPath.section) else {
            assertionFailure("Invalid section")
            return
        }
        
        switch listSection {
        case .launches:
            let launch = self.launches[indexPath.row]
            self.pushToDetail(launchID: launch.id)
        case .loading:
            if self.activeRequest == nil {
                self.loadMoreLaunchesIfTheyExist()
            }
        }
    }
}

