
import Foundation
import Result
let SBXURL = "sbxcloud.com"


public struct SBXDataUtil {
    
    public enum ApiMethod: String {
        case GET = "GET"
        case POST = "POST"
        case PUT = "PUT"
    }
    
    
    public enum SBXDataError: Error {
        case NoData
        case InvalidJSON
        case ConversionFailed
        case FieldNotPresent
        case ErrorResponse(String)        
        case CustomError(Error)
    }
    
    
    public static func getJSON(method: ApiMethod, host:String, port:Int?, secure:Bool = true ,path: String, body: Data?, params: [String: String]?, headers: [String: String], completionHandler: @escaping (Result<[String:Any], SBXDataError>) -> ()) {
        
        var url = URLComponents()
        url.host = host
        
        if let port = port {
            url.port = port
        }
        
        
        url.path = path
        url.scheme = secure ? "https":"http"
        
        if let params = params {
            url.queryItems = params.map {
                return URLQueryItem(name: $0, value: $1)
            }
        }
        
        guard let endpoint = url.url else {
            completionHandler(.failure(.NoData))
            return
        }
        
        
        var clientReq = URLRequest(url: endpoint)
        
        clientReq.httpBody = body
        
        
        headers.forEach {
            clientReq.addValue($1, forHTTPHeaderField: $0)
        }
        
        clientReq.addValue("application/json", forHTTPHeaderField: "accept")
        clientReq.httpMethod = method.rawValue
        URLSession.shared.dataTask(with: clientReq){
            (data, res, err) in
            
            
            guard err == nil else{
                completionHandler(.failure(.CustomError(err!)))
                return
            }
            
            do {
                
                guard let data = data else {
                    completionHandler(.failure(.NoData))
                    return
                }
                
                guard let json:[String:Any] =  try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                    completionHandler(.failure(.ConversionFailed))
                    return
                }
                
                // TODO: improve this to link fetched results!
                completionHandler(.success(json))
                
            }catch {
                completionHandler(.failure(.CustomError(error)))
            }
        }.resume()
    }
    
    static func find(token:String, appKey:String, query:[String:Any], completionHandler: @escaping (Result<[String:Any],SBXDataError>) -> () ){
        
        let headers = [
            "accept-language": "es,en;q=0.8",
            "Authorization": "Bearer \(token)",
            "App-Key": "Bearer \(appKey)",
            "content-type": "application/json;charset=UTF-8",
            "accept": "application/json",
            "cache-control": "no-cache"
        ]
        
        guard  let postData = try? JSONSerialization.data(withJSONObject: query, options: .prettyPrinted) else {
            completionHandler(.failure(.InvalidJSON))
            return
        }
        
        getJSON(method: .POST, host:SBXURL,port:nil, secure:true,path: "/api/data/v1/row/find", body: postData, params: nil, headers: headers, completionHandler:completionHandler)
        
    
    }



}




