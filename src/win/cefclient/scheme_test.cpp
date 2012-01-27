// Copyright (c) 2009 The Chromium Embedded Framework Authors. All rights
// reserved. Use of this source code is governed by a BSD-style license that
// can be found in the LICENSE file.

#include "include/cef_wrapper.h"
#include "resource_util.h"
#include "scheme_test.h"
#include "string_util.h"
#include "util.h"

#if defined(OS_WIN)
#include "resource.h"
#endif


// Implementation of the schema handler for client:// requests.
class ClientSchemeHandler : public CefSchemeHandler
{
public:
  ClientSchemeHandler() : offset_(0) {}

  virtual bool ProcessRequest(CefRefPtr<CefRequest> request,
                              CefRefPtr<CefSchemeHandlerCallback> callback)
                              OVERRIDE
  {
    REQUIRE_IO_THREAD();

    bool handled = false;

    AutoLock lock_scope(this);
    
    std::string url = request->GetURL();
    if(strstr(url.c_str(), "handler.html") != NULL) {
      // Build the response html
      data_ = "<html><head><title>Client Scheme Handler</title></head><body>"
              "This contents of this page page are served by the "
              "ClientSchemeHandler class handling the client:// protocol."
              "<br/>You should see an image:"
              "<br/><img src=\"client://tests/client.png\"><pre>";
      
      // Output a string representation of the request
      std::string dump;
      DumpRequestContents(request, dump);
      data_.append(dump);

      data_.append("</pre><br/>Try the test form:"
                   "<form method=\"POST\" action=\"handler.html\">"
                   "<input type=\"text\" name=\"field1\">"
                   "<input type=\"text\" name=\"field2\">"
                   "<input type=\"submit\">"
                   "</form></body></html>");

      handled = true;

      // Set the resulting mime type
      mime_type_ = "text/html";
    }
    else if(strstr(url.c_str(), "client.png") != NULL) {
      // Load the response image
#if defined(OS_WIN)
      DWORD dwSize;
      LPBYTE pBytes;
      if(LoadBinaryResource(IDS_LOGO, dwSize, pBytes)) {
        data_ = std::string(reinterpret_cast<const char*>(pBytes), dwSize);
        handled = true;
        // Set the resulting mime type
        mime_type_ = "image/jpg";
      }
#elif (defined(OS_MACOSX) || defined(OS_LINUX))
      if(LoadBinaryResource("logo.png", data_)) {
        handled = true;
        // Set the resulting mime type
        mime_type_ = "image/png";
      }
#else
#error "Unsupported platform"
#endif
    }

    if (handled) {
      // Indicate the headers are available.
      callback->HeadersAvailable();
      return true;
    }

    return false;
  }

  virtual void GetResponseHeaders(CefRefPtr<CefResponse> response,
                                  int64& response_length,
                                  CefString& redirectUrl) OVERRIDE
  {
    REQUIRE_IO_THREAD();

    ASSERT(!data_.empty());

    response->SetMimeType(mime_type_);
    response->SetStatus(200);

    // Set the resulting response length
    response_length = data_.length();
  }

  virtual void Cancel() OVERRIDE
  {
    REQUIRE_IO_THREAD();
  }

  virtual bool ReadResponse(void* data_out,
                            int bytes_to_read,
                            int& bytes_read,
                            CefRefPtr<CefSchemeHandlerCallback> callback)
                            OVERRIDE
  {
    REQUIRE_IO_THREAD();

    bool has_data = false;
    bytes_read = 0;

    AutoLock lock_scope(this);

    if(offset_ < data_.length()) {
      // Copy the next block of data into the buffer.
      int transfer_size =
          std::min(bytes_to_read, static_cast<int>(data_.length() - offset_));
      memcpy(data_out, data_.c_str() + offset_, transfer_size);
      offset_ += transfer_size;

      bytes_read = transfer_size;
      has_data = true;
    }

    return has_data;
  }

private:
  std::string data_;
  std::string mime_type_;
  size_t offset_;

  IMPLEMENT_REFCOUNTING(ClientSchemeHandler);
  IMPLEMENT_LOCKING(ClientSchemeHandler);
};

// Implementation of the factory for for creating schema handlers.
class ClientSchemeHandlerFactory : public CefSchemeHandlerFactory
{
public:
  // Return a new scheme handler instance to handle the request.
  virtual CefRefPtr<CefSchemeHandler> Create(CefRefPtr<CefBrowser> browser,
                                             const CefString& scheme_name,
                                             CefRefPtr<CefRequest> request)
                                             OVERRIDE
  {
    REQUIRE_IO_THREAD();
    return new ClientSchemeHandler();
  }

  IMPLEMENT_REFCOUNTING(ClientSchemeHandlerFactory);
};

void InitSchemeTest()
{
  CefRegisterCustomScheme("client", true, false, false);
  CefRegisterSchemeHandlerFactory("client", "tests",
      new ClientSchemeHandlerFactory());
}

void RunSchemeTest(CefRefPtr<CefBrowser> browser)
{
  browser->GetMainFrame()->LoadURL("client://tests/handler.html");
}
