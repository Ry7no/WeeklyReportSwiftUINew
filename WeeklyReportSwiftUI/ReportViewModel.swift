//
//  ReportViewModel.swift
//  WeeklyReportSwiftUI
//
//  Created by Ryan@work on 2022/6/21.
//

import SwiftUI
import PDFKit
import UIKit
import Foundation
import MessageUI
import CoreText
import QuartzCore

class ReportViewModel: ObservableObject {
    
    var interactionController = UIDocumentInteractionController()
    var outputFileURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("\(UserDefaults.standard.string(forKey: "outputFileName") ?? "Swift").pdf")
    
    var outputHtmlURL: URL?
    
    func clearDiskCache() {
        let fileManager = FileManager.default
        let myDocuments = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let diskCacheStorageBaseUrl = myDocuments.appendingPathComponent("\(UserDefaults.standard.string(forKey: "outputFileName")!).pdf")
        guard let filePaths = try? fileManager.contentsOfDirectory(at: diskCacheStorageBaseUrl, includingPropertiesForKeys: nil, options: []) else { return }
        for filePath in filePaths {
            try? fileManager.removeItem(at: filePath)
        }
    }
    
    func clearAllFile() {
        let fileManager = FileManager.default
        let myDocuments = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        do {
            try fileManager.removeItem(at: myDocuments)
            print("Clear all file")
        } catch {
            return
        }
    }
    
    func exportViewToPDF() {
        
//        let outputFileURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("SwiftUI.pdf")
//        let pageSize = CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        
        let pageSize = CGSize(width: 595.2, height: 841.8)
        
        //View to render on PDF
        let myUIHostingController = UIHostingController(rootView: ContentView())
        myUIHostingController.view.frame = CGRect(origin: .zero, size: pageSize)
        
        
        //Render the view behind all other views
        guard let rootVC = UIApplication.shared.windows.first?.rootViewController else {
            print("ERROR: Could not find root ViewController.")
            return
        }
        rootVC.addChild(myUIHostingController)
        //at: 0 -> draws behind all other views
        //at: UIApplication.shared.windows.count -> draw in front
        rootVC.view.insertSubview(myUIHostingController.view, at: 0)
        
        //Render the PDF
        let pdfRenderer = UIGraphicsPDFRenderer(bounds: CGRect(origin: .zero, size: pageSize))
        DispatchQueue.main.async {
            do {
                try pdfRenderer.writePDF(to: self.outputFileURL, withActions: { (context) in
                    context.beginPage()
                    myUIHostingController.view.layer.render(in: context.cgContext)
                })
                print("wrote file to: \(self.outputFileURL.path)")
            } catch {
                print("Could not create PDF file: \(error.localizedDescription)")
            }
            
            //Remove rendered view
            myUIHostingController.removeFromParent()
            myUIHostingController.view.removeFromSuperview()
            
            
        }
    }
    
    func exportHtmlToPdf(_ string: String, title: String) {
        // 1. Create a print formatter

        let html = "<h2>\(title)</h2><br><h4>\(string)</h4>" // create some text as the body of the PDF with html.

        let fmt = UIMarkupTextPrintFormatter(markupText: html)

        // 2. Assign print formatter to UIPrintPageRenderer

        let render = UIPrintPageRenderer()
        render.addPrintFormatter(fmt, startingAtPageAt: 0)

        // 3. Assign paperRect and printableRect

        let page = CGRect(x: 10, y: 10, width: 595.2, height: 841.8) // A4, 72 dpi, x and y are horizontal and vertical margins
        let printable = page.insetBy(dx: 0, dy: 0)

        render.setValue(NSValue(cgRect: page), forKey: "paperRect")
        render.setValue(NSValue(cgRect: printable), forKey: "printableRect")

        // 4. Create PDF context and draw

        let pdfData = NSMutableData()
        UIGraphicsBeginPDFContextToData(pdfData, CGRect.zero, nil)

        for i in 1...render.numberOfPages {

            UIGraphicsBeginPDFPage();
            let bounds = UIGraphicsGetPDFContextBounds()
            render.drawPage(at: i - 1, in: bounds)
        }

        UIGraphicsEndPDFContext();

        // 5. Save PDF file
//        let path = "\(NSTemporaryDirectory())\(title).pdf"
//        outputHtmlURL = URL(string: path)
//        DispatchQueue.main.async {
//            do {
//                try pdfData.write(toFile: path, atomically: true)
//                print("wrote HTML pdf to: \(path)")
//            } catch {
//                print("Could not create PDF file: \(error.localizedDescription)")
//            }
//        }

        let path = "\(NSTemporaryDirectory())\(title).pdf"
        outputHtmlURL = URL(string: path)
        pdfData.write(toFile: path, atomically: true)
        print("open \(path)") // check if we got the path right.
            // open share dialog
            print("opening share dialog")
            // Initialize Document Interaction Controller
//            self.interactionController = UIDocumentInteractionController(url: URL(fileURLWithPath: path))
            // Configure Document Interaction Controller
//            self.interactionController.delegate = self
            // Present Open In Menu
//            self.interactionController!.presentOptionsMenu(from: yourexportbarbuttonoutlet, animated: true)
            // create an outlet from an Export bar button outlet, then use it as the `from` argument
    }
    
    
    
    func sendEmail(data:Data?){
        if( MFMailComposeViewController.canSendMail() ) {
            let mailComposer = MFMailComposeViewController()
//            mailComposer.mailComposeDelegate = self

            mailComposer.setToRecipients(["john@stackoverflow.com", "mrmins@mydomain.com", "anotheremail@email.com"])
            mailComposer.setSubject("Cotización")
            mailComposer.setMessageBody("My body message", isHTML: true)

            if let fileData = data {
                mailComposer.addAttachmentData(fileData, mimeType: "application/pdf", fileName: "MyFileName.pdf")
           }


//           self.present(mailComposer, animated: true, completion: nil)
//                return
        }
        print("Email is not configured")

    }
}

//struct PDFKitRepresentedView: UIViewRepresentable {
//    
//    let url: URL
//
//    init(_ url: URL) {
//        self.url = url
//    }
//
//    func makeUIView(context: UIViewRepresentableContext<PDFKitRepresentedView>) -> PDFKitRepresentedView.UIViewType {
//        // Create a `PDFView` and set its `PDFDocument`.
//        let pdfView = PDFView()
//        pdfView.document = PDFDocument(url: self.url)
//        return pdfView
//    }
//
//    func updateUIView(_ uiView: UIView, context: UIViewRepresentableContext<PDFKitRepresentedView>) {
//        // Update the view.
//    }
//}


